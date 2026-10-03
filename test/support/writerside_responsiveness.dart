import 'dart:convert';
import 'dart:io';
import 'package:busymark/src/core/diagnostic.dart';
import 'package:busymark/src/core/path_utils.dart';
import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:busymark/src/workspace/document_buffer.dart';
import 'package:busymark/src/workspace/workspace_service.dart';
import 'package:busymark/src/writerside/writerside_document.dart';
import 'package:busymark/src/writerside/writerside_document_resolver.dart';
import 'package:busymark/src/writerside/writerside_model.dart';
import 'package:busymark/src/writerside/writerside_module_service.dart';
import 'package:busymark/src/writerside/writerside_project.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

Future<Directory> syntheticProject() async {
  final root = await Directory.systemTemp.createTemp(
    'busymark-responsiveness-',
  );
  addTearDown(() => root.delete(recursive: true));
  await Directory(p.join(root.path, 'topics')).create();
  await File(p.join(root.path, 'writerside.cfg')).writeAsString(
    '<ihp name="Test"><topics dir="topics"/><instance src="guide.tree"/></ihp>',
  );
  await File(p.join(root.path, 'guide.tree')).writeAsString(
    '<instance-profile id="guide" name="Guide" start-page="home.md"><toc-element topic="home.md"/><toc-element topic="other.md"/></instance-profile>',
  );
  await File(p.join(root.path, 'topics/home.md')).writeAsString('# Home\n');
  await File(p.join(root.path, 'topics/other.md')).writeAsString('# Other\n');
  return root;
}

/// Root discovery observes a limited part of images; symbol discovery revisits
/// the same directory with a fresh budget and can observe the whole listing.
Future<Directory> resourceLimitedProject() async {
  final root = await syntheticProject();
  await File(p.join(root.path, 'writerside.cfg')).writeAsString(
    '<ihp name="Test"><topics dir="topics"/><images dir="images"/>'
    '<resources dir="resources"/><instance src="guide.tree"/></ihp>',
  );
  for (final directory in ['images', 'resources']) {
    await Directory(p.join(root.path, directory)).create();
    for (var i = 0; i < 6; i++) {
      await File(
        p.join(root.path, directory, '$i.png'),
      ).writeAsString('fixture');
    }
  }
  return root;
}

class CountingModule extends WritersideModuleService {
  int loads = 0;
  @override
  Future<WritersideModule> load(
    String rootPath, {
    WorkspaceScanOptions? options,
    Map<String, String> sourceOverrides = const {},
  }) {
    loads++;
    return super.load(
      rootPath,
      options: options,
      sourceOverrides: sourceOverrides,
    );
  }
}

Future<DocumentBuffer> responsivenessBuffer(
  WorkspaceService service,
  String path,
) async {
  final load = await service.loadTextWithSnapshot(path);
  return DocumentBuffer.file(
    id: path,
    filePath: path,
    text: load.text,
    snapshot: load.snapshot,
    format: load.format,
  );
}

Object diagnosticSnapshot(Diagnostic d) => [
  d.toJson(),
  d.sourceSpan?.toJson(),
  d.relatedSpans.map((s) => s.toJson()).toList(),
];
Object _inline(BusyInline n) => [
  n.kind.name,
  n.text,
  n.destination,
  n.attributes,
  n.children.map(_inline).toList(),
];
Object _block(BusyBlock n) => [
  n.id,
  n.kind.name,
  n.attributes,
  n.rawSource,
  n.sourceSpan?.toJson(),
  n.preserveRaw,
  n.isSourceOnly,
  n.isGenerated,
  n.isSourceProtected,
  n.dirty,
  n.inlines.map(_inline).toList(),
  n.children.map(_block).toList(),
];
Object _node(WritersideDocumentNode n) => [
  n.runtimeType.toString(),
  n.span.toJson(),
  n.rawSource,
  n.isModified,
  n.plainText,
  if (n.provenance case final v?) [v.moduleRoot, v.topicPath, v.occurrence],
  if (n is WritersideElementNode)
    [
      n.name,
      n.qualifiedName,
      n.attributes,
      n.qualifiedAttributes
          .map((a) => [a.name, a.qualifiedName, a.value])
          .toList(),
      n.attributeSpans.map((k, v) => MapEntry(k, v.toJson())),
      n.semanticKind?.name,
      n.schemaKnown,
      n.children.map(_node).toList(),
    ],
  if (n is WritersideMarkdownBlockNode) _block(n.block),
];
Object documentSemanticSnapshot(WritersideDocument d) => [
  d.filePath,
  d.source,
  d.format.name,
  d.isWellFormed,
  d.nodes.map(_node).toList(),
];
Object _toc(TocNode n) => [
  n.topicFileName,
  n.referenceTopicFileName,
  n.referenceInstanceId,
  n.href,
  n.tocTitle,
  n.id,
  n.acceptsWebFileNames,
  n.acceptsWebFileNamesRef,
  n.targetForAcceptWebFileNames,
  n.instanceCondition,
  n.customFilter,
  n.origin,
  n.hidden,
  n.workInProgress,
  n.span.toJson(),
  n.sourceTreePath,
  n.sourceTocPath,
  n.sourceXmlPath,
  n.included,
  n.includeFrom,
  n.includeElementId,
  n.includeResolutionError,
  n.children.map(_toc).toList(),
];
Object projectSemanticSnapshot(WritersideProject project) => jsonDecode(
  jsonEncode([
    project.rootPath,
    project.activeModuleId,
    project.activeInstanceId,
    project.moduleDiscoveryComplete,
    project.diagnostics.map(diagnosticSnapshot).toList(),
    project.index.symbols
        .map(
          (s) => [
            s.name,
            s.qualifiedName,
            s.kind.name,
            s.moduleId,
            s.filePath,
            s.span?.toJson(),
            s.instanceCondition,
            s.scopeSpan?.toJson(),
          ],
        )
        .toList(),
    project.index.references
        .map(
          (s) => [
            s.value,
            s.kind.name,
            s.moduleId,
            s.filePath,
            s.span.toJson(),
            s.origin,
            s.sourceValue,
            s.scopeReference,
            s.nullable,
          ],
        )
        .toList(),
    project.modules
        .map(
          (m) => [
            m.rootPath,
            m.sourceOverrides,
            m.validatedImageDirs,
            m.topicDiscoveryComplete,
            m.variablesAvailable,
            m.unparsedTopicReferences.toList(),
            m.config.topicsDirs,
            m.config.imagesDirs,
            m.config.apiSpecificationsDir,
            m.config.buildConfigDir,
            m.config.varsFile,
            m.config.categoriesFile,
            m.variables
                .map(
                  (v) => [
                    v.name,
                    v.value,
                    v.instanceCondition,
                    v.span.toJson(),
                  ],
                )
                .toList(),
            m.categories
                .map((v) => [v.id, v.name, v.order, v.span.toJson()])
                .toList(),
            m.diagnostics.map(diagnosticSnapshot).toList(),
            m.instances
                .map(
                  (i) => [
                    i.id,
                    i.name,
                    i.startPage,
                    i.status,
                    i.isLibrary,
                    i.sourceTreePath,
                    i.version,
                    i.globalVersion,
                    i.webPath,
                    i.keymapsMode,
                    i.allowSearchEngineIndexing,
                    i.offlineArtifact,
                    i.diagnostics.map(diagnosticSnapshot).toList(),
                    i.tocRoots.map(_toc).toList(),
                    i.navigationTocRoots.map(_toc).toList(),
                  ],
                )
                .toList(),
            m.sourceFiles.map(
              (k, v) =>
                  MapEntry(k, [v.path, v.text, v.failure, v.api?.toJson()]),
            ),
            m.referenceData.glossary,
            m.referenceData.shortcuts,
            m.referenceData.layouts,
            m.topics.map((t) {
              final resolved = const WritersideDocumentResolver().resolve(
                t.document,
                WritersideResolveContext(
                  module: m,
                  topic: t,
                  instance: m.instances.firstOrNull,
                  modulesByOrigin: project.modulesByOrigin,
                ),
              );
              return [
                t.fileName,
                t.id,
                t.title,
                t.webFileName,
                t.topicRoot,
                t.format.name,
                t.semanticElementNames,
                t.elementIds.map((e) => [e.id, e.span.toJson()]).toList(),
                documentSemanticSnapshot(t.document),
                t.markdown?.busyDocument.blocks.map(_block).toList(),
                t.markdown?.mode.name,
                t.markdown?.headings
                    .map(
                      (h) => [
                        h.level,
                        h.text,
                        h.id,
                        h.generatedId,
                        h.span.toJson(),
                      ],
                    )
                    .toList(),
                t.markdown?.links
                    .map((v) => [v.text, v.destination, v.span.toJson()])
                    .toList(),
                t.markdown?.images
                    .map((v) => [v.alt, v.destination, v.span.toJson()])
                    .toList(),
                t.markdown?.codeBlocks
                    .map((v) => [v.language, v.content, v.span.toJson()])
                    .toList(),
                t.markdown?.xmlBlocks
                    .map((v) => [v.rawXml, v.elementName, v.span.toJson()])
                    .toList(),
                t.markdown?.variables
                    .map((v) => [v.name, v.escaped, v.span.toJson()])
                    .toList(),
                t.markdown?.diagnostics.map(diagnosticSnapshot).toList(),
                t.diagnostics.map(diagnosticSnapshot).toList(),
                documentSemanticSnapshot(resolved.document),
                resolved.title,
                resolved.diagnostics.map(diagnosticSnapshot).toList(),
              ];
            }).toList(),
          ],
        )
        .toList(),
  ]),
);
