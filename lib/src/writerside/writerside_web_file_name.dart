import 'dart:convert';

import 'package:path/path.dart' as p;

import '../core/diagnostic.dart';
import '../core/source_span.dart';
import 'writerside_document.dart';
import 'writerside_document_resolver.dart';
import 'writerside_model.dart';

class WritersideEffectiveWebFileName {
  const WritersideEffectiveWebFileName({
    required this.value,
    required this.custom,
    this.sourceSpan,
  });

  final String value;
  final bool custom;
  final SourceSpan? sourceSpan;

  bool get isValid => WritersideWebFileNameResolver.isValid(value);
}

class WritersidePublishedTopic {
  const WritersidePublishedTopic({
    required this.hostModule,
    required this.sourceModule,
    required this.instance,
    required this.topic,
  });

  final WritersideModule hostModule;
  final WritersideModule sourceModule;
  final WritersideInstance instance;
  final WritersideTopic topic;

  String get identity => '${sourceModule.rootPath}\u0000${topic.filePath}';
}

class WritersideWebFileNameResolver {
  const WritersideWebFileNameResolver({
    this.documentResolver = const WritersideDocumentResolver(),
  });

  final WritersideDocumentResolver documentResolver;

  WritersideEffectiveWebFileName resolve({
    required WritersideModule module,
    required WritersideTopic topic,
    required WritersideInstance instance,
    required Map<String, WritersideModule> modulesByOrigin,
    String? topicFileName,
  }) {
    final resolved = documentResolver.resolve(
      topic.document,
      WritersideResolveContext(
        module: module,
        topic: topic,
        instance: instance,
        modulesByOrigin: modulesByOrigin,
      ),
    );
    final scope = resolved.document.format == WritersideDocumentFormat.xmlTopic
        ? resolved.document.rootElement?.children ??
              const <WritersideDocumentNode>[]
        : resolved.document.nodes;
    final authored = scope
        .whereType<WritersideElementNode>()
        .where((element) => element.name == 'web-file-name')
        .firstOrNull;
    final custom = authored?.plainText.trim();
    if (custom != null && custom.isNotEmpty) {
      return WritersideEffectiveWebFileName(
        value: custom,
        custom: true,
        sourceSpan: authored!.span,
      );
    }
    return WritersideEffectiveWebFileName(
      value: defaultName(
        topicFileName ?? topic.fileName,
        disablePreprocessing:
            module.config.settings.disableWebNamePreprocessing == true,
      ),
      custom: false,
    );
  }

  static String defaultName(
    String topicFileName, {
    required bool disablePreprocessing,
  }) {
    final rawBase = p.basenameWithoutExtension(topicFileName).trim();
    final base = disablePreprocessing
        ? rawBase
              .replaceAll(RegExp(r'[^\p{L}\p{N}._~-]+', unicode: true), '-')
              .replaceAll(RegExp(r'^-+|-+$'), '')
        : rawBase
              .toLowerCase()
              .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), '-')
              .replaceAll(RegExp(r'^-+|-+$'), '');
    return '$base.html';
  }

  static bool isValid(String name) =>
      name.isNotEmpty &&
      utf8.encode(name).length <= 240 &&
      name.toLowerCase().endsWith('.html') &&
      !name.startsWith('.') &&
      !RegExp(r'[/\\\x00-\x1f\x7f?#:%]').hasMatch(name) &&
      p.basename(name) == name;
}

List<WritersidePublishedTopic> writersidePublishedTopicsForInstance({
  required WritersideModule hostModule,
  required WritersideInstance instance,
  required Map<String, WritersideModule> modulesByOrigin,
}) {
  final result = <WritersidePublishedTopic>[];
  final seen = <String>{};

  void add(String? reference, WritersideModule sourceModule) {
    if (reference == null) return;
    final topic = sourceModule.topicByReference(reference);
    if (topic == null) return;
    final published = WritersidePublishedTopic(
      hostModule: hostModule,
      sourceModule: sourceModule,
      instance: instance,
      topic: topic,
    );
    if (seen.add(published.identity)) result.add(published);
  }

  void visit(TocNode node, WritersideModule inheritedModule) {
    final sourceModule = node.origin == null
        ? inheritedModule
        : modulesByOrigin[node.origin];
    if (sourceModule == null) return;
    if (node.referenceInstanceId == null ||
        node.referenceInstanceId == instance.id) {
      add(node.topicReference, sourceModule);
    }
    for (final child in node.children) {
      visit(child, sourceModule);
    }
  }

  add(instance.startPage, hostModule);
  for (final root in instance.navigationTocRoots) {
    visit(root, hostModule);
  }
  return List.unmodifiable(result);
}

List<Diagnostic> writersideWebFileNameDiagnostics(
  List<WritersideModule> modules,
) {
  final diagnostics = <Diagnostic>[];
  final origins = <String, WritersideModule>{
    for (final module in modules)
      (module.config.moduleName?.trim().isNotEmpty == true
              ? module.config.moduleName!.trim()
              : p.basename(module.rootPath)):
          module,
  };
  const resolver = WritersideWebFileNameResolver();
  for (final host in modules) {
    for (final instance in host.instances.where((value) => !value.isLibrary)) {
      final byName =
          <
            String,
            (WritersidePublishedTopic, WritersideEffectiveWebFileName)
          >{};
      for (final published in writersidePublishedTopicsForInstance(
        hostModule: host,
        instance: instance,
        modulesByOrigin: origins,
      )) {
        final effective = resolver.resolve(
          module: published.sourceModule,
          topic: published.topic,
          instance: instance,
          modulesByOrigin: origins,
        );
        if (!effective.isValid) {
          diagnostics.add(
            Diagnostic(
              code: 'writerside.web-file-name.invalid',
              severity: DiagnosticSeverity.error,
              filePath: published.topic.filePath,
              args: {
                'instanceId': instance.id,
                'webFileName': effective.value,
                'topic': published.topic.fileName,
              },
              sourceSpan: effective.sourceSpan,
            ),
          );
          continue;
        }
        final key = effective.value.toLowerCase();
        final previous = byName[key];
        if (previous == null) {
          byName[key] = (published, effective);
          continue;
        }
        diagnostics.add(
          Diagnostic(
            code: 'writerside.web-file-name.collision',
            severity: DiagnosticSeverity.error,
            filePath: published.topic.filePath,
            args: {
              'instanceId': instance.id,
              'webFileName': effective.value,
              'firstTopic': previous.$1.topic.fileName,
              'secondTopic': published.topic.fileName,
            },
            sourceSpan: effective.sourceSpan,
            relatedSpans: [
              previous.$2.sourceSpan ??
                  SourceSpan.entireFile(previous.$1.topic.filePath, ''),
            ],
          ),
        );
      }
    }
  }
  return sortDiagnostics(diagnostics);
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
