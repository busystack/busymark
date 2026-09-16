import 'dart:io';

import 'package:busymark/src/core/busymark_exception.dart';
import 'package:busymark/src/workspace/workspace_service.dart';
import 'package:busymark/src/writerside/writerside_title_editor.dart';
import 'package:busymark/src/writerside/writerside_toc_editor.dart';
import 'package:busymark/src/writerside/writerside_toc_navigation.dart';
import 'package:busymark/src/writerside/writerside_toc_presentation.dart';
import 'package:busymark/src/writerside/writerside_topic_creator.dart';
import 'package:busymark/src/writerside/writerside_topic_removal_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

void main() {
  Future<Directory> fixture() async {
    final root = await Directory.systemTemp.createTemp(
      'busymark-toc-workspace-',
    );
    addTearDown(() => root.delete(recursive: true));
    final source = Directory('test/fixtures/writerside/toc_ui');
    await for (final item in source.list(recursive: true)) {
      final destination = p.join(
        root.path,
        p.relative(item.path, from: source.path),
      );
      if (item is Directory) {
        await Directory(destination).create(recursive: true);
      }
      if (item is File) {
        await File(destination).parent.create(recursive: true);
        await item.copy(destination);
      }
    }
    return root;
  }

  test(
    'row titles, markers and included source identity use selected context',
    () async {
      final root = await fixture();
      final workspace = await const WorkspaceService().openPath(root.path);
      final module = workspace.writersideModule!;
      final guide = module.instances.firstWhere(
        (instance) => instance.id == 'guide',
      );
      final api = module.instances.firstWhere(
        (instance) => instance.id == 'api',
      );
      final presenter = WritersideTocPresenter(module: module, instance: guide);
      final rows = guide.navigationTocRoots
          .expand((node) => node.flatten())
          .map(presenter.present)
          .toList();
      expect(rows.first.label, 'Welcome to BusyMark');
      expect(rows.first.home, isTrue);
      expect(
        rows.singleWhere((row) => row.topic?.id == 'details').label,
        'XML guide title',
      );
      expect(
        rows.singleWhere((row) => row.topic?.id == 'reused').label,
        'Navigation-only title',
      );
      expect(
        rows.singleWhere((row) => row.topic?.id == 'hidden').hidden,
        isTrue,
      );
      expect(
        rows.singleWhere((row) => row.label == 'Empty group').empty,
        isTrue,
      );
      expect(
        rows.singleWhere((row) => row.external).tooltip,
        'https://www.jetbrains.com/writerside/',
      );
      final included = guide.navigationTocRoots
          .expand((node) => node.flatten())
          .singleWhere((node) => node.topicFileName == 'shared.md');
      expect(presenter.present(included).included, isTrue);
      expect(included.canEditStructure, isFalse);
      expect(included.sourceTocPath, isNull);
      expect(included.sourceXmlPath, [0, 0]);
      final ownerSource = await File(included.sourceTreePath!).readAsString();
      final span = writersideTocSourceSpan(
        filePath: included.sourceTreePath!,
        source: ownerSource,
        path: included.sourceXmlPath!,
        xmlChildren: true,
        identity: WritersideTocNodeIdentity.fromNode(included),
      );
      expect(span!.startOffset, ownerSource.indexOf('<toc-element'));
      expect(
        WritersideTocPresenter(
          module: module,
          instance: api,
        ).present(api.navigationTocRoots.first).label,
        'API-specific title',
      );
    },
  );

  test(
    'linking retains source bytes and rejects a now-present candidate',
    () async {
      final root = await fixture();
      const service = WorkspaceService();
      final workspace = await service.openPath(root.path);
      final topic = workspace.writersideModule!.topicByReference(
        'unlinked.md',
      )!;
      final bytes = await File(topic.filePath).readAsBytes();
      final tree = p.join(root.path, 'guide.tree');
      const request = WritersideTocInsertRequest(
        placement: WritersideTopicCreatePlacement.root,
        topicReference: 'unlinked.md',
      );
      await service.insertWritersideTocElement(
        workspace,
        treePath: tree,
        request: request,
        expectedTopicPath: topic.filePath,
        expectedTopicSource: topic.document.source,
      );
      expect(await File(topic.filePath).readAsBytes(), bytes);
      final before = await File(tree).readAsString();
      await expectLater(
        service.insertWritersideTocElement(
          workspace,
          treePath: tree,
          request: request,
          expectedTopicPath: topic.filePath,
          expectedTopicSource: topic.document.source,
        ),
        throwsA(isA<BusyMarkException>()),
      );
      expect(await File(tree).readAsString(), before);
    },
  );

  test(
    'home reassignment preserves other instances and unrelated attributes',
    () async {
      final root = await fixture();
      const service = WorkspaceService();
      final workspace = await service.openPath(root.path);
      final guide = workspace.writersideModule!.instances.firstWhere(
        (instance) => instance.id == 'guide',
      );
      final apiFile = File(p.join(root.path, 'api.tree'));
      final apiBefore = await apiFile.readAsString();
      await service.setWritersideHomePage(
        workspace,
        treePath: guide.sourceTreePath,
        nodePath: [1, 0],
        expectedIdentity: WritersideTocNodeIdentity.fromNode(
          guide.tocRoots[1].children[0],
        ),
      );
      final xml = XmlDocument.parse(
        await File(guide.sourceTreePath).readAsString(),
      ).rootElement;
      expect(xml.getAttribute('start-page'), 'details.topic');
      expect(xml.getAttribute('name'), 'User Guide');
      expect(await apiFile.readAsString(), apiBefore);
    },
  );

  for (final scenario in [
    (
      name: 'empty instance',
      attributes: '',
      children: '',
      topic: true,
      home: 'unlinked.md',
    ),
    (
      name: 'groups only',
      attributes: '',
      children: '<toc-element toc-title="Group"/>',
      topic: true,
      home: 'unlinked.md',
    ),
    (
      name: 'existing home',
      attributes: ' start-page="home.md"',
      children: '',
      topic: true,
      home: 'home.md',
    ),
    (
      name: 'library',
      attributes: ' is-library="true"',
      children: '',
      topic: true,
      home: null,
    ),
    (
      name: 'empty group insertion',
      attributes: '',
      children: '',
      topic: false,
      home: null,
    ),
    (
      name: 'existing nested topic',
      attributes: '',
      children:
          '<toc-element toc-title="Group"><toc-element topic="home.md"/></toc-element>',
      topic: true,
      home: null,
    ),
  ]) {
    test(
      'linking initializes the first-topic home page: ${scenario.name}',
      () async {
        final root = await fixture();
        final tree = File(p.join(root.path, 'guide.tree'));
        await tree.writeAsString(
          '<instance-profile id="guide" name="Guide"${scenario.attributes}>${scenario.children}</instance-profile>',
        );
        const service = WorkspaceService();
        final workspace = await service.openPath(root.path);
        final topic = workspace.writersideModule!.topicByReference(
          'unlinked.md',
        )!;
        final bytes = await File(topic.filePath).readAsBytes();
        await service.insertWritersideTocElement(
          workspace,
          treePath: tree.path,
          request: WritersideTocInsertRequest(
            placement: WritersideTopicCreatePlacement.root,
            topicReference: scenario.topic ? 'unlinked.md' : null,
            tocTitle: scenario.topic ? null : 'Empty group',
          ),
          expectedTopicPath: scenario.topic ? topic.filePath : null,
          expectedTopicSource: scenario.topic ? topic.document.source : null,
        );
        final xml = XmlDocument.parse(await tree.readAsString()).rootElement;
        expect(xml.getAttribute('start-page'), scenario.home);
        expect(xml.getAttribute('name'), 'Guide');
        expect(await File(topic.filePath).readAsBytes(), bytes);
        expect(
          xml.childElements.last.getAttribute(
            scenario.topic ? 'topic' : 'toc-title',
          ),
          scenario.topic ? 'unlinked.md' : 'Empty group',
        );
      },
    );
  }

  test(
    'first linked topic and home assignment share the same publication guard',
    () async {
      final root = await fixture();
      final tree = File(p.join(root.path, 'guide.tree'));
      await tree.writeAsString('<instance-profile id="guide"/>');
      const concurrent = '<instance-profile id="guide" start-page="home.md"/>';
      final service = WorkspaceService(
        writersideTocEditor: WritersideTocEditor(
          beforeTreePublish: (_) => tree.writeAsString(concurrent),
        ),
      );
      final workspace = await service.openPath(root.path);
      final topic = workspace.writersideModule!.topicByReference(
        'unlinked.md',
      )!;
      await expectLater(
        service.insertWritersideTocElement(
          workspace,
          treePath: tree.path,
          request: const WritersideTocInsertRequest(
            placement: WritersideTopicCreatePlacement.root,
            topicReference: 'unlinked.md',
          ),
          expectedTopicPath: topic.filePath,
          expectedTopicSource: topic.document.source,
        ),
        throwsA(isA<BusyMarkException>()),
      );
      expect(await tree.readAsString(), concurrent);
    },
  );

  test(
    'title transaction rolls back both files on a concurrent dirty-buffer guard',
    () async {
      final root = await fixture();
      var dirty = false;
      final service = WorkspaceService(
        afterBatchFileCommit: (_, count) async {
          if (count == 1) dirty = true;
        },
      );
      final workspace = await service.openPath(root.path);
      final guide = workspace.writersideModule!.instances.firstWhere(
        (instance) => instance.id == 'guide',
      );
      final session = await service.prepareWritersideTitleEdit(
        workspace,
        treePath: guide.sourceTreePath,
        tocPath: [0],
        identity: WritersideTocNodeIdentity.fromNode(guide.tocRoots.first),
        topicModuleRoot: workspace.writersideModule!.rootPath,
        topicPath: workspace.writersideModule!
            .topicByReference(guide.tocRoots.first.topicReference!)!
            .filePath,
      );
      var committed = false;
      await expectLater(
        service.editWritersideTitles(
          session,
          const WritersideTitleEdit(
            title: 'Changed',
            tocTitle: 'Changed navigation',
          ),
          validateBeforeCommit: () {
            if (dirty) throw StateError('dirty buffer');
          },
          onCommitted: (_, _) => committed = true,
        ),
        throwsStateError,
      );
      expect(committed, isFalse);
      expect(
        await File(session.topic.filePath).readAsString(),
        session.topicLoad.text,
      );
      expect(
        await File(session.treePath).readAsString(),
        session.treeLoad.text,
      );
    },
  );

  test(
    'XML duplicate copies source, changes only root ID, adds basic sibling',
    () async {
      final root = await fixture();
      const service = WorkspaceService();
      final workspace = await service.openPath(root.path);
      final guide = workspace.writersideModule!.instances.firstWhere(
        (instance) => instance.id == 'guide',
      );
      final topic = workspace.writersideModule!.topicByReference(
        'details.topic',
      )!;
      final path = await service.duplicateWritersideTopic(
        workspace,
        treePath: guide.sourceTreePath,
        tocPath: [1, 0],
        identity: WritersideTocNodeIdentity.fromNode(
          guide.tocRoots[1].children.first,
        ),
        topicPath: topic.filePath,
        expectedSource: topic.document.source,
        newName: 'details-copy',
        validateBeforePublish: () async {},
      );
      expect(await File(topic.filePath).readAsString(), topic.document.source);
      expect(
        await File(path).readAsString(),
        topic.document.source.replaceFirst('id="details"', 'id="details-copy"'),
      );
      final element =
          XmlDocument.parse(await File(guide.sourceTreePath).readAsString())
              .findAllElements('toc-element')
              .singleWhere(
                (e) => e.getAttribute('topic') == 'details-copy.topic',
              );
      expect(element.attributes, hasLength(1));
      expect(element.childElements, isEmpty);
    },
  );

  test(
    'sort revalidates title dependencies before publishing the tree',
    () async {
      final root = await fixture();
      final changed = File(p.join(root.path, 'topics/hidden.md'));
      final service = WorkspaceService(
        writersideTocEditor: WritersideTocEditor(
          beforeTreePublish: (_) async {
            await changed.writeAsString('# Z changed concurrently\n');
          },
        ),
      );
      final workspace = await service.openPath(root.path);
      final guide = workspace.writersideModule!.instances.firstWhere(
        (instance) => instance.id == 'guide',
      );
      final before = await File(guide.sourceTreePath).readAsString();
      await expectLater(
        service.sortWritersideTocChildren(
          workspace,
          treePath: guide.sourceTreePath,
          nodePath: [1],
          identity: WritersideTocNodeIdentity.fromNode(guide.tocRoots[1]),
        ),
        throwsA(isA<BusyMarkException>()),
      );
      expect(await File(guide.sourceTreePath).readAsString(), before);
      expect(await changed.readAsString(), '# Z changed concurrently\n');
    },
  );

  test(
    'safe deletion rechecks dirty-buffer guard and rolls back earlier edits',
    () async {
      final root = await fixture();
      const service = WorkspaceService();
      final workspace = await service.openPath(root.path);
      final topic = workspace.writersideModule!.topicByReference('reused.md')!;
      final originals = <String, String>{};
      await for (final entity in root.list(recursive: true)) {
        if (entity is File) {
          originals[entity.path] = await entity.readAsString();
        }
      }
      final analysis = await service.analyzeWritersideTopicRemoval(
        workspace,
        topicPath: topic.filePath,
        mode: WritersideTopicRemovalMode.removeFromInstance,
        treePath: p.join(root.path, 'guide.tree'),
        nodePath: [1, 1],
      );
      var checks = 0;
      await expectLater(
        service.applyWritersideTopicRemoval(
          workspace,
          WritersideTopicRemovalRequest(
            analysis: analysis,
            updateUsagesAutomatically: true,
          ),
          validateBeforeCommit: (paths) {
            expect(paths, contains(p.join(root.path, 'guide.tree')));
            if (++checks > 1) throw StateError('became dirty');
          },
        ),
        throwsStateError,
      );
      expect(checks, greaterThan(1));
      for (final entry in originals.entries) {
        expect(await File(entry.key).readAsString(), entry.value);
      }
    },
  );
}
