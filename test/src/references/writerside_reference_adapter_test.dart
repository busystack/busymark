import 'dart:io';
import 'package:busymark/src/references/reference_index.dart';
import 'package:busymark/src/references/markdown_references.dart';
import 'package:busymark/src/references/writerside_reference_adapter.dart';
import 'package:busymark/src/writerside/writerside_project.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'authored include origins, explicit IDs, ambiguity and instance availability share the existing resolver',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'reference-writerside-',
      );
      addTearDown(() => root.delete(recursive: true));
      Future<void> write(String path, String source) async {
        final file = File('${root.path}/$path');
        await file.parent.create(recursive: true);
        await file.writeAsString(source);
      }

      for (final module in ['main', 'shared']) {
        await write(
          '$module/writerside.cfg',
          '<ihp><module name="$module"/><topics dir="topics"/><instance src="guide.tree"/><instance src="beta.tree"/></ihp>',
        );
        for (final instance in ['guide', 'beta']) {
          await write(
            '$module/$instance.tree',
            '<instance-profile id="$instance" start-page="${module == 'main' ? 'source' : 'target'}.topic"><toc-element topic="${module == 'main' ? 'source' : 'target'}.topic"/>${module == 'main' ? '<toc-element origin="shared" topic="target.topic"/>' : ''}</instance-profile>',
          );
        }
      }
      await write(
        'main/topics/source.topic',
        '<topic id="source" title="Source"><var name="target" value="target.topic#explicit"/><p><a origin="shared" href="%target%">Variable</a><a origin="shared" href="target.topic#explicit">Element</a><a origin="shared" href="dup.topic">Ambiguous</a></p><include origin="shared" from="target.topic" element-id="piece"/></topic>',
      );
      await write(
        'shared/topics/target.topic',
        '<topic id="target" title="Target"><chapter id="explicit" title="Actual"><p>Target</p></chapter><snippet id="piece" instance="beta"><p><a href="#explicit">Reusable link</a></p></snippet></topic>',
      );
      await write(
        'shared/topics/first/dup.topic',
        '<topic id="duplicate-a" title="A"><p>A</p></topic>',
      );
      await write(
        'shared/topics/nested/dup.topic',
        '<topic id="duplicate-b" title="B"><p>B</p></topic>',
      );
      final project = await const WritersideProjectService().load(root.path);
      ReferenceIndex index(String instance) {
        final topics = project.modules.expand((m) => m.topics).toList();
        final value = ReferenceIndex(
          root: root.path,
          parsed: [
            for (final topic in topics)
              ParsedReferenceDocument(
                ReferenceDocument(
                  identity: topic.filePath,
                  path: topic.filePath,
                  title: topic.title ?? topic.fileName,
                  source: topic.document.source,
                ),
              ),
          ],
          ownedPaths: topics.map((t) => t.filePath).toSet(),
        );
        addWritersideReferences(value, project.index, instance);
        return value;
      }

      final guide = index('guide');
      final authored = guide.references
          .where((r) => r.source.path!.endsWith('source.topic'))
          .toList();
      final element = authored.singleWhere(
        (r) => r.authored.destination.contains('#explicit'),
      );
      expect(element.resolution, ReferenceResolution.resolved);
      expect(element.target!.anchor, 'explicit');
      expect(element.target!.moduleId, 'shared');
      expect(
        authored
            .singleWhere((r) => r.authored.destination == '%target%')
            .resolution,
        ReferenceResolution.resolved,
      );
      expect(
        authored
            .singleWhere((r) => r.authored.destination == 'dup.topic')
            .resolution,
        ReferenceResolution.ambiguous,
      );
      final include = authored
          .where((r) => r.authored.kind == AuthoredReferenceKind.include)
          .toList();
      expect(include, isNotEmpty);
      expect(include.map((r) => r.authored.origin), everyElement('shared'));
      expect(
        include.map((r) => r.resolution),
        everyElement(ReferenceResolution.unavailable),
      );
      expect(
        index('beta').references
            .where(
              (r) =>
                  r.source.path!.endsWith('source.topic') &&
                  r.authored.kind == AuthoredReferenceKind.include,
            )
            .map((r) => r.resolution),
        everyElement(ReferenceResolution.resolved),
      );
      // Reuse indexes its library occurrence once, not an expansion in the caller.
      expect(
        guide.references.where((r) => r.authored.destination == '#explicit'),
        hasLength(1),
      );
      expect(
        guide.references
            .singleWhere((r) => r.authored.destination == '#explicit')
            .source
            .path,
        endsWith('target.topic'),
      );
    },
  );
}
