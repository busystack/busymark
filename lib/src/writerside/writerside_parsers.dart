import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

import '../core/diagnostic.dart';
import '../core/path_utils.dart';
import '../core/source_span.dart';
import '../markdown/busymark_document.dart';
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

class WritersideBuildProfilesParser {
  const WritersideBuildProfilesParser();

  WritersideBuildProfilesConfig parse(String filePath, String source) {
    final diagnostics = <Diagnostic>[];
    XmlDocument? document;
    try {
      document = XmlDocument.parse(source);
    } on Object catch (error) {
      diagnostics.add(
        _xmlError(
          'writerside.build-profiles.invalid-xml',
          filePath,
          source,
          error,
        ),
      );
    }
    if (document == null) {
      return WritersideBuildProfilesConfig(
        filePath: filePath,
        diagnostics: diagnostics,
      );
    }
    final root = document.rootElement;
    if (root.name.local != 'buildprofiles') {
      diagnostics.add(
        Diagnostic(
          code: 'writerside.build-profiles.invalid-root',
          severity: DiagnosticSeverity.error,
          filePath: filePath,
          sourceSpan: _elementSpan(filePath, source, root.name.local),
        ),
      );
    }

    final globalValues = _valuesFromParent(filePath, source, root, diagnostics);
    final instanceValues = <String, WritersideBuildProfileValues>{};
    for (final profile in root.childElements.where(
      (element) => element.name.local == 'build-profile',
    )) {
      final instanceId = profile.getAttribute('instance')?.trim();
      if (instanceId == null || instanceId.isEmpty) {
        diagnostics.add(
          Diagnostic(
            code: 'writerside.build-profiles.missing-instance',
            severity: DiagnosticSeverity.warning,
            filePath: filePath,
            sourceSpan: _elementSpan(filePath, source, 'build-profile'),
          ),
        );
        continue;
      }
      final parsed = _valuesFromParent(filePath, source, profile, diagnostics);
      final previous = instanceValues[instanceId];
      instanceValues[instanceId] = WritersideBuildProfileValues(
        noindexContent: parsed.noindexContent ?? previous?.noindexContent,
        offlineDocs: parsed.offlineDocs ?? previous?.offlineDocs,
      );
    }
    return WritersideBuildProfilesConfig(
      filePath: filePath,
      globalValues: globalValues,
      instanceValues: Map.unmodifiable(instanceValues),
      diagnostics: diagnostics,
    );
  }

  WritersideBuildProfileValues _valuesFromParent(
    String filePath,
    String source,
    XmlElement parent,
    List<Diagnostic> diagnostics,
  ) {
    final variables = parent.childElements
        .where((element) => element.name.local == 'variables')
        .firstOrNull;
    if (variables == null) {
      return const WritersideBuildProfileValues();
    }
    bool? noindexContent;
    bool? offlineDocs;
    for (final variable in variables.childElements) {
      // Status-specific values apply only to the matching build invocation.
      // The instance editor represents the unconditional profile value and
      // must not overwrite or misreport a release/EAP-specific override.
      if (variable.getAttribute('status') != null) {
        continue;
      }
      switch (variable.name.local) {
        case 'noindex-content':
          noindexContent = _booleanValue(
            filePath,
            source,
            variable,
            diagnostics,
          );
        case 'offline-docs':
          offlineDocs = _booleanValue(filePath, source, variable, diagnostics);
      }
    }
    return WritersideBuildProfileValues(
      noindexContent: noindexContent,
      offlineDocs: offlineDocs,
    );
  }

  bool? _booleanValue(
    String filePath,
    String source,
    XmlElement element,
    List<Diagnostic> diagnostics,
  ) {
    final value = element.innerText.trim();
    if (value == 'true') {
      return true;
    }
    if (value == 'false') {
      return false;
    }
    diagnostics.add(
      Diagnostic(
        code: 'writerside.build-profiles.invalid-boolean',
        severity: DiagnosticSeverity.warning,
        filePath: filePath,
        args: {'name': element.name.local, 'value': value},
        sourceSpan: _elementSpan(filePath, source, element.name.local, value),
      ),
    );
    return null;
  }
}

class WritersideInstanceGroupsParser {
  const WritersideInstanceGroupsParser();

  WritersideInstanceGroupsConfig parse(String filePath, String source) {
    final diagnostics = <Diagnostic>[];
    XmlDocument? document;
    try {
      document = XmlDocument.parse(source);
    } on Object catch (error) {
      diagnostics.add(
        _xmlError(
          'writerside.instance-groups.invalid-xml',
          filePath,
          source,
          error,
        ),
      );
    }
    if (document == null) {
      return WritersideInstanceGroupsConfig(
        filePath: filePath,
        diagnostics: diagnostics,
      );
    }
    final root = document.rootElement;
    if (root.name.local != 'instance-groups') {
      diagnostics.add(
        Diagnostic(
          code: 'writerside.instance-groups.invalid-root',
          severity: DiagnosticSeverity.error,
          filePath: filePath,
          sourceSpan: _elementSpan(filePath, source, root.name.local),
        ),
      );
    }
    final groups = <String, WritersideInstanceGroup>{};
    for (final element in root.childElements.where(
      (element) => element.name.local == 'group',
    )) {
      final id = element.getAttribute('id')?.trim() ?? '';
      final instances = (element.getAttribute('instances') ?? '')
          .split(',')
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toSet();
      final span = _elementSpan(filePath, source, 'group', id);
      if (id.isEmpty || instances.isEmpty) {
        diagnostics.add(
          Diagnostic(
            code: 'writerside.instance-groups.invalid-group',
            severity: DiagnosticSeverity.error,
            filePath: filePath,
            sourceSpan: span,
          ),
        );
        continue;
      }
      final previous = groups[id];
      if (previous != null) {
        diagnostics.add(
          Diagnostic(
            code: 'writerside.instance-groups.duplicate-id',
            severity: DiagnosticSeverity.error,
            filePath: filePath,
            args: {'id': id},
            sourceSpan: span,
            relatedSpans: [previous.span],
          ),
        );
        continue;
      }
      groups[id] = WritersideInstanceGroup(
        id: id,
        instanceIds: Set.unmodifiable(instances),
        span: span,
      );
    }
    return WritersideInstanceGroupsConfig(
      filePath: filePath,
      groups: Map.unmodifiable(groups),
      diagnostics: diagnostics,
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
    final treeEntries = _treeEntries(
      filePath,
      source,
      root,
      tocParentPath: const [],
      diagnostics: diagnostics,
    );
    final tocRoots = treeEntries.whereType<TocNode>().toList();
    final isLibrary = root.getAttribute('is-library') == 'true';
    final hasTopic = tocRoots
        .expand((node) => node.flatten())
        .any((node) => node.topicFileName != null);
    if (startPage == null && !isLibrary && hasTopic) {
      diagnostics.add(
        Diagnostic(
          code: 'writerside.tree.missing-start-page',
          severity: DiagnosticSeverity.error,
          filePath: filePath,
          sourceSpan: _elementSpan(filePath, source, root.name.local),
        ),
      );
    }
    final status = root.getAttribute('status') ?? 'release';
    if (!{'release', 'deprecated', 'eap'}.contains(status)) {
      diagnostics.add(
        Diagnostic(
          code: 'writerside.tree.invalid-status',
          severity: DiagnosticSeverity.warning,
          filePath: filePath,
          args: {'status': status},
          sourceSpan: _elementSpan(filePath, source, root.name.local, status),
        ),
      );
    }
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
    final declaredIds = <String, SourceSpan>{};
    for (final entry in _flattenTreeEntries(treeEntries)) {
      final declaredId = switch (entry) {
        TocNode() => entry.id,
        WritersideTocSnippet() => entry.id,
        WritersideTocInclude() => null,
      };
      if (declaredId == null || declaredId.isEmpty) {
        continue;
      }
      final previous = declaredIds[declaredId];
      if (previous != null) {
        diagnostics.add(
          Diagnostic(
            code: 'writerside.tree.duplicate-element-id',
            severity: DiagnosticSeverity.error,
            filePath: filePath,
            args: {'id': declaredId},
            sourceSpan: entry.span,
            relatedSpans: [previous],
          ),
        );
      } else {
        declaredIds[declaredId] = entry.span;
      }
    }
    return WritersideInstance(
      id: id.isEmpty ? p.basenameWithoutExtension(filePath) : id,
      name: name.isEmpty ? id : name,
      sourceTreePath: filePath,
      startPage: startPage,
      status: status,
      isLibrary: isLibrary,
      tocRoots: tocRoots,
      diagnostics: diagnostics,
      treeEntries: treeEntries,
    );
  }

  List<WritersideTreeEntry> _treeEntries(
    String filePath,
    String source,
    XmlElement parent, {
    required List<int>? tocParentPath,
    required List<Diagnostic> diagnostics,
  }) {
    final result = <WritersideTreeEntry>[];
    var tocIndex = 0;
    for (final child in parent.childElements) {
      switch (child.name.local) {
        case 'toc-element':
          final tocPath = tocParentPath == null
              ? null
              : [...tocParentPath, tocIndex];
          result.add(
            _tocNode(
              filePath,
              source,
              child,
              tocPath: tocPath,
              diagnostics: diagnostics,
            ),
          );
          tocIndex++;
        case 'include':
          final from = _trimmedAttribute(child, 'from');
          final elementId = _trimmedAttribute(child, 'element-id');
          final span = _elementSpan(filePath, source, 'include', elementId);
          if (from == null || elementId == null) {
            diagnostics.add(
              Diagnostic(
                code: 'writerside.tree.invalid-include',
                severity: DiagnosticSeverity.error,
                filePath: filePath,
                sourceSpan: span,
              ),
            );
          }
          result.add(
            WritersideTocInclude(
              from: from,
              elementId: elementId,
              instanceCondition: _trimmedAttribute(child, 'instance'),
              customFilter: _trimmedAttribute(child, 'filter'),
              origin: _trimmedAttribute(child, 'origin'),
              useFilters: _commaSeparatedAttribute(child, 'use-filter'),
              span: span,
            ),
          );
        case 'snippet':
          final id = _trimmedAttribute(child, 'id');
          final span = _elementSpan(filePath, source, 'snippet', id);
          if (id == null) {
            diagnostics.add(
              Diagnostic(
                code: 'writerside.tree.missing-snippet-id',
                severity: DiagnosticSeverity.error,
                filePath: filePath,
                sourceSpan: span,
              ),
            );
          }
          result.add(
            WritersideTocSnippet(
              id: id,
              instanceCondition: _trimmedAttribute(child, 'instance'),
              customFilter: _trimmedAttribute(child, 'filter'),
              origin: _trimmedAttribute(child, 'origin'),
              entries: _treeEntries(
                filePath,
                source,
                child,
                tocParentPath: null,
                diagnostics: diagnostics,
              ),
              span: span,
            ),
          );
      }
    }
    return result;
  }

  TocNode _tocNode(
    String filePath,
    String source,
    XmlElement element, {
    required List<int>? tocPath,
    required List<Diagnostic> diagnostics,
  }) {
    final topic = _trimmedAttribute(element, 'topic');
    final reference = _trimmedAttribute(element, 'ref');
    final referenceInstance = _trimmedAttribute(element, 'in');
    final href = _trimmedAttribute(element, 'href');
    final redirectTarget = _trimmedAttribute(
      element,
      'target-for-accept-web-file-names',
    );
    final span = _elementSpan(
      filePath,
      source,
      'toc-element',
      topic ?? reference,
    );
    if ((reference == null) != (referenceInstance == null)) {
      diagnostics.add(
        Diagnostic(
          code: 'writerside.tree.invalid-cross-instance-reference',
          severity: DiagnosticSeverity.error,
          filePath: filePath,
          sourceSpan: span,
        ),
      );
    }
    final primaryTargets = [
      topic,
      reference,
      href,
      redirectTarget,
    ].whereType<String>().length;
    if (primaryTargets > 1) {
      diagnostics.add(
        Diagnostic(
          code: 'writerside.tree.conflicting-toc-targets',
          severity: DiagnosticSeverity.error,
          filePath: filePath,
          sourceSpan: span,
        ),
      );
    }
    final entries = _treeEntries(
      filePath,
      source,
      element,
      tocParentPath: tocPath,
      diagnostics: diagnostics,
    );
    return TocNode(
      topicFileName: topic,
      referenceTopicFileName: reference,
      referenceInstanceId: referenceInstance,
      href: href,
      tocTitle: _trimmedAttribute(element, 'toc-title'),
      id: _trimmedAttribute(element, 'id'),
      acceptsWebFileNames: _trimmedAttribute(element, 'accepts-web-file-names'),
      acceptsWebFileNamesRef: _trimmedAttribute(
        element,
        'accepts-web-file-names-ref',
      ),
      targetForAcceptWebFileNames: redirectTarget,
      instanceCondition: _trimmedAttribute(element, 'instance'),
      customFilter: _trimmedAttribute(element, 'filter'),
      origin: _trimmedAttribute(element, 'origin'),
      hidden: element.getAttribute('hidden') == 'true',
      workInProgress: element.getAttribute('wip') == 'true',
      entries: entries,
      children: entries.whereType<TocNode>().toList(),
      sourceTreePath: filePath,
      sourceTocPath: tocPath,
      span: span,
    );
  }

  Iterable<WritersideTreeEntry> _flattenTreeEntries(
    List<WritersideTreeEntry> entries,
  ) sync* {
    for (final entry in entries) {
      yield entry;
      switch (entry) {
        case TocNode():
          yield* _flattenTreeEntries(entry.childEntries);
        case WritersideTocSnippet():
          yield* _flattenTreeEntries(entry.entries);
        case WritersideTocInclude():
          break;
      }
    }
  }

  String? _trimmedAttribute(XmlElement element, String name) {
    final value = element.getAttribute(name)?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  List<String> _commaSeparatedAttribute(XmlElement element, String name) {
    final value = _trimmedAttribute(element, name);
    if (value == null) {
      return const [];
    }
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
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
            from: _writersideAttributeValue(match.group(0)!, 'from'),
            elementId: _writersideAttributeValue(match.group(0)!, 'element-id'),
            nullable:
                _writersideAttributeValue(match.group(0)!, 'nullable') ==
                'true',
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
    final videos = <WritersideVideo>[];
    void collectVideos(Iterable<BusyBlock> blocks) {
      for (final block in blocks) {
        if (block.kind == BusyBlockKind.video) {
          final src = block.attributes['src']?.trim() ?? '';
          videos.add(
            WritersideVideo(
              source: src,
              previewSource: _trimmedOrNull(block.attributes['preview-src']),
              width: _trimmedOrNull(block.attributes['width']),
              height: _trimmedOrNull(block.attributes['height']),
              miniPlayer: block.attributes['mini-player'] == 'true',
              borderEffect: block.attributes['border-effect'] ?? 'none',
              span: block.sourceSpan ?? SourceSpan.entireFile(filePath, source),
            ),
          );
        }
        collectVideos(block.children);
      }
    }

    collectVideos(parsed.busyDocument.blocks);
    final topicDiagnostics = <Diagnostic>[
      ..._writersideMarkdownDiagnostics(parsed.diagnostics),
      for (final video in videos)
        if (video.source.isEmpty)
          Diagnostic(
            code: 'writerside.video.missing-source',
            severity: DiagnosticSeverity.warning,
            filePath: filePath,
            sourceSpan: video.span,
          ),
    ];
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
      videos: videos,
      variables: parsed.variables,
      includes: includes,
      diagnostics: sortDiagnostics(topicDiagnostics),
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
    final videos = <WritersideVideo>[];
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
          case 'video':
            final src = element.getAttribute('src')?.trim() ?? '';
            final span = _elementSpan(filePath, source, 'video', src);
            videos.add(
              WritersideVideo(
                source: src,
                previewSource: _trimmedOrNull(
                  element.getAttribute('preview-src'),
                ),
                width: _trimmedOrNull(element.getAttribute('width')),
                height: _trimmedOrNull(element.getAttribute('height')),
                miniPlayer: element.getAttribute('mini-player') == 'true',
                borderEffect: element.getAttribute('border-effect') ?? 'none',
                span: span,
              ),
            );
            if (src.isEmpty) {
              diagnostics.add(
                Diagnostic(
                  code: 'writerside.video.missing-source',
                  severity: DiagnosticSeverity.warning,
                  filePath: filePath,
                  sourceSpan: span,
                ),
              );
            }
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
      videos: videos,
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
  r'<include\b[^>]*>',
  caseSensitive: false,
  dotAll: true,
);

String? _writersideAttributeValue(String element, String attribute) {
  final match = RegExp(
    '${RegExp.escape(attribute)}\\s*=\\s*(["\\\'])(.*?)\\1',
    caseSensitive: false,
    dotAll: true,
  ).firstMatch(element);
  return match?.group(2);
}

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

String? _trimmedOrNull(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
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
