import '../support/writerside_responsiveness.dart';
import 'dart:io';
import 'dart:isolate';

import 'package:busymark/src/core/busymark_exception.dart';
import 'package:busymark/src/core/path_utils.dart';
import 'package:busymark/src/workspace/workspace_service.dart';
import 'package:busymark/src/writerside/writerside_execution.dart';
import 'package:busymark/src/writerside/writerside_input_snapshot.dart';
import 'package:busymark/src/writerside/writerside_module_service.dart';
import 'package:busymark/src/writerside/writerside_project.dart';
import 'package:busymark/src/writerside/writerside_source_loader.dart';
import 'package:busymark/src/writerside/writerside_topic_creator.dart';
import 'package:busymark/src/writerside/writerside_topic_removal_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('rejected source size remains an input to freshness checking', () async {
    final root = await syntheticProject();
    final source = File(p.join(root.path, 'topics/example.txt'));
    await source.writeAsString('this is over the limit');
    final recorder = WritersideInputRecorder(root.path);
    final rejected = await recorder.observe(
      () => const WritersideSourceLoader(maximumBytes: 8).load(
        reference: 'example.txt',
        documentPath: p.join(root.path, 'topics/home.md'),
        workspaceRoot: root.path,
      ),
    );
    expect(rejected.failure, 'too-large');
    expect(await recorder.snapshot.isCurrent(), isTrue);
    await source.writeAsString('valid');
    expect(await recorder.snapshot.isCurrent(), isFalse);
    final fresh = await const WritersideSourceLoader(maximumBytes: 8).load(
      reference: 'example.txt',
      documentPath: p.join(root.path, 'topics/home.md'),
      workspaceRoot: root.path,
    );
    expect(fresh.text, 'valid');
  });
  test('bounded topic rejection detects recovery on the real worker', () async {
    final root = await syntheticProject();
    final source = File(p.join(root.path, 'topics/other.md'));
    await source.writeAsString('x' * 513);
    const loader = WritersideModuleService(
      scanOptions: WorkspaceScanOptions(maxParsedFileBytes: 256),
    );
    final rejected = await loader.load(root.path);
    expect(rejected.unparsedTopicReferences, contains('other.md'));
    expect(await rejected.inputSnapshot!.isCurrent(), isTrue);
    await source.writeAsString('# Recovered\n');
    expect(await rejected.inputSnapshot!.isCurrent(), isFalse);
    final fresh = await loader.load(root.path);
    expect(fresh.topicByReference('other.md')!.title, 'Recovered');
  });
  test('oversized buffer overrides retain their consumed-input hash', () async {
    final root = await syntheticProject();
    final path = p.join(root.path, 'topics/other.md');
    const loader = WritersideModuleService(
      scanOptions: WorkspaceScanOptions(maxParsedFileBytes: 256),
    );
    final rejected = await loader.load(
      root.path,
      sourceOverrides: {path: 'x' * 513},
    );
    expect(rejected.unparsedTopicReferences, contains('other.md'));
    expect(rejected.inputSnapshot!.reads[path]!.override, isTrue);
    expect(rejected.inputSnapshot!.reads[path]!.bytes, 513);
    expect(await rejected.inputSnapshot!.isCurrent(), isTrue);
    expect(
      await rejected.inputSnapshot!.matchesDisk(requireDiskSources: true),
      isFalse,
    );
  });
  test(
    'unreadable sources keep error diagnostics and invalidate on recovery',
    () async {
      final root = await syntheticProject();
      final source = File(p.join(root.path, 'topics/example.txt'));
      await source.writeAsString('readable after recovery');
      final chmod = await Process.run('chmod', ['000', source.path]);
      expect(chmod.exitCode, 0);
      addTearDown(() async {
        await Process.run('chmod', ['600', source.path]);
      });
      final recorder = WritersideInputRecorder(root.path);
      Future<WritersideSourceFile> load() =>
          const WritersideSourceLoader().load(
            reference: 'example.txt',
            documentPath: p.join(root.path, 'topics/home.md'),
            workspaceRoot: root.path,
          );
      final rejected = await recorder.observe(load);
      expect(rejected.failure, 'missing');
      expect(recorder.snapshot.failedReads, contains(source.path));
      expect(await recorder.snapshot.isCurrent(), isTrue);
      final extended = WritersideInputRecorder.fromSnapshot(recorder.snapshot);
      expect(await extended.snapshot.isCurrent(), isTrue);
      await Process.run('chmod', ['600', source.path]);
      expect(await recorder.snapshot.isCurrent(), isFalse);
      expect(await extended.snapshot.isCurrent(), isFalse);
      expect((await load()).text, 'readable after recovery');
    },
    skip: !Platform.isLinux,
  );
  test(
    'real execution transfers results and propagates worker failures',
    () async {
      const execution = WritersideExecution();
      expect(
        await execution.run(_isolateName, 0),
        isNot(Isolate.current.debugName),
      );
      await expectLater(execution.run(_fail, 0), throwsStateError);
    },
  );
  for (final fixture in [
    'basic_project',
    'conformance_project',
    'markdown_export_compatibility',
  ]) {
    test(
      'worker preserves full parsed and resolved models: $fixture',
      () async {
        final root = p.absolute('test/fixtures/writerside/$fixture');
        final foreground = await const WritersideProjectService(
          moduleService: WritersideModuleService(
            execution: WritersideExecution(useWorker: false),
          ),
        ).load(root);
        final worker = await const WritersideProjectService().load(root);
        expect(
          projectSemanticSnapshot(worker),
          projectSemanticSnapshot(foreground),
        );
        expect(await worker.inputsMatchDisk(), isTrue);
      },
    );
  }
  for (final fault in [
    'malformed XML',
    'missing configured root',
    'unsafe include',
    'scan limit',
  ]) {
    test('worker preserves failure and safety diagnostics: $fault', () async {
      final root = await syntheticProject();
      switch (fault) {
        case 'malformed XML':
          await File(
            p.join(root.path, 'topics/broken.topic'),
          ).writeAsString('<topic id="broken"><p>');
        case 'missing configured root':
          await File(p.join(root.path, 'writerside.cfg')).writeAsString(
            '<ihp><topics dir="missing"/><instance src="guide.tree"/></ihp>',
          );
        case 'unsafe include':
          await File(
            p.join(root.path, 'topics/other.md'),
          ).writeAsString('# Other\n<include from="../../outside.topic"/>\n');
        case 'scan limit':
          break;
      }
      final options = fault == 'scan limit'
          ? const WorkspaceScanOptions(maxParsedDocuments: 1)
          : const WorkspaceScanOptions();
      final foreground = await WritersideModuleService(
        execution: const WritersideExecution(useWorker: false),
        scanOptions: options,
      ).load(root.path);
      final worker = await WritersideModuleService(
        scanOptions: options,
      ).load(root.path);
      expect(
        worker.diagnostics.map(diagnosticSnapshot).toList(),
        foreground.diagnostics.map(diagnosticSnapshot).toList(),
      );
      expect(
        worker.topics.map((t) => documentSemanticSnapshot(t.document)).toList(),
        foreground.topics
            .map((t) => documentSemanticSnapshot(t.document))
            .toList(),
      );
      expect(
        worker.unparsedTopicReferences,
        foreground.unparsedTopicReferences,
      );
      expect(worker.topicDiscoveryComplete, foreground.topicDiscoveryComplete);
      expect(worker.diagnostics, isNotEmpty);
    });
  }
  test(
    'preparation consumes complete overlays once, then selects with zero loads',
    () async {
      final root = await syntheticProject();
      final loader = CountingModule();
      final service = WorkspaceService(writersideService: loader);
      var workspace = await service.openPath(root.path);
      final a = await responsivenessBuffer(
        service,
        p.join(root.path, 'topics/home.md'),
      );
      final b = await responsivenessBuffer(
        service,
        p.join(root.path, 'topics/other.md'),
      );
      final sources = {a.filePath!: a.text, b.filePath!: b.text};
      loader.loads = 0;
      workspace = await service.prepareDocument(workspace, b, sources);
      expect(loader.loads, 1);
      expect(workspace.markdown?.source, b.text);
      expect(workspace.writersideProject!.activeInstanceId, 'guide');
      expect(service.documentOutline(workspace, b).first.text, 'Other');
      expect(service.buildDocumentPreview(workspace, b), isNotNull);
      loader.loads = 0;
      workspace = await service.prepareDocument(workspace, a, sources);
      expect(loader.loads, 0);
      expect(workspace.markdown?.filePath, a.filePath);
      final edited = b.copyWith(
        text: '# Dependency edited\n',
        dirty: true,
        revision: b.revision + 1,
      );
      workspace = await service.prepareDocument(workspace, a, {
        a.filePath!: a.text,
        b.filePath!: edited.text,
      });
      expect(loader.loads, 1);
      expect(
        workspace.writersideModule!.topicByReference('other.md')!.title,
        'Dependency edited',
      );
      loader.loads = 0;
      workspace = await service.prepareDocument(workspace, a, {
        a.filePath!: a.text,
      });
      expect(loader.loads, 1);
      expect(workspace.sourceOverrides, {a.filePath!: a.text});
      expect(
        workspace.writersideModule!.topicByReference('other.md')!.title,
        'Other',
      );
    },
  );
  test('reuse checks equal-size disk dependencies and added inputs', () async {
    final root = await syntheticProject();
    final loader = CountingModule();
    final service = WorkspaceService(writersideService: loader);
    var workspace = await service.openPath(root.path);
    final a = await responsivenessBuffer(
      service,
      p.join(root.path, 'topics/home.md'),
    );
    workspace = await service.prepareDocument(workspace, a, {
      a.filePath!: a.text,
    });
    loader.loads = 0;
    await File(p.join(root.path, 'topics/other.md')).writeAsString('# OTHER\n');
    workspace = await service.prepareDocument(workspace, a, {
      a.filePath!: a.text,
    });
    expect(loader.loads, 1);
    expect(
      workspace.writersideModule!.topicByReference('other.md')!.title,
      'OTHER',
    );
    await File(p.join(root.path, 'topics/added.md')).writeAsString('# Added\n');
    workspace = await service.prepareDocument(workspace, a, {
      a.filePath!: a.text,
    });
    expect(workspace.writersideModule!.topicByReference('added.md'), isNotNull);
  });
  test(
    'planned path exclusions cannot hide a new colon-named dependency',
    () async {
      final root = await syntheticProject();
      final project = await const WritersideProjectService().load(root.path);
      final ignored = p.join(root.path, 'topics/other.md');
      expect(await project.inputsMatchDisk(ignoredPaths: {ignored}), isTrue);
      await File(
        p.join(root.path, 'topics/other.md:dependent.md'),
      ).writeAsString('# Added dependency\n');
      expect(await project.inputsMatchDisk(ignoredPaths: {ignored}), isFalse);
    },
  );
  test(
    'configuration overlay rediscovery retains symbols and diagnostics',
    () async {
      final root = await syntheticProject();
      await Directory(p.join(root.path, 'alternate')).create();
      await File(p.join(root.path, 'alternate/logo.png')).writeAsBytes([0]);
      final service = WorkspaceService(writersideService: CountingModule());
      final workspace = await service.openPath(root.path);
      final a = await responsivenessBuffer(
        service,
        p.join(root.path, 'topics/home.md'),
      );
      final config = File(p.join(root.path, 'writerside.cfg'));
      final text = (await config.readAsString()).replaceFirst(
        '<topics',
        '<images dir="alternate"/><topics',
      );
      final prepared = await service.prepareDocument(workspace, a, {
        a.filePath!: a.text,
        config.path: text,
      });
      expect(
        prepared.writersideProject!.index.symbols
            .where((s) => s.kind == WritersideSymbolKind.image)
            .map((s) => s.filePath),
        contains(p.join(root.path, 'alternate/logo.png')),
      );
      final selected = await service.prepareDocument(prepared, a, {
        a.filePath!: a.text,
        config.path: text,
      });
      expect(
        selected.writersideProject!.index.symbols.map((s) => s.filePath),
        contains(p.join(root.path, 'alternate/logo.png')),
      );
    },
  );
  test(
    'creation returns its typed publication result without reopening',
    () async {
      final root = await syntheticProject();
      final loader = CountingModule();
      final service = WorkspaceService(writersideService: loader);
      final workspace = await service.openPath(root.path);
      loader.loads = 0;
      final result = await service.createWritersideTopic(
        workspace,
        const WritersideTopicCreateRequest(title: 'New', fileName: 'new.md'),
      );
      expect(result, isA<WritersideTopicCreateResult>());
      expect(result.topicPath, p.join(root.path, 'topics/new.md'));
      expect(
        loader.loads,
        2,
      ); // Current module and pre-publication identity only.
      expect(await File(result.topicPath).readAsString(), contains('# New'));
      expect(
        await File(p.join(root.path, 'guide.tree')).readAsString(),
        contains('new.md'),
      );
    },
  );
  test(
    'removal application shares one ownership-checked fresh project',
    () async {
      final root = await syntheticProject();
      final loader = CountingModule();
      final service = WorkspaceService(writersideService: loader);
      final workspace = await service.openPath(root.path);
      final analysis = await service.analyzeWritersideTopicRemoval(
        workspace,
        topicPath: p.join(root.path, 'topics/other.md'),
        mode: WritersideTopicRemovalMode.safeDeleteFile,
      );
      loader.loads = 0;
      await service.applyWritersideTopicRemoval(
        workspace,
        WritersideTopicRemovalRequest(
          analysis: analysis,
          updateUsagesAutomatically: true,
        ),
      );
      expect(loader.loads, 1);
      expect(await File(analysis.topicPath).exists(), isFalse);
    },
  );
  for (final change in [
    'changed',
    'added',
    'removed',
    'tree',
    'configuration',
  ]) {
    test(
      'supplied removal model rejects $change input before fingerprint collection',
      () async {
        final root = await syntheticProject();
        const service = WritersideTopicRemovalService();
        final project = await const WritersideProjectService().load(root.path);
        final path = p.join(root.path, 'topics/other.md');
        final analysis = await service.analyze(
          project: project,
          topicPath: path,
          mode: WritersideTopicRemovalMode.safeDeleteFile,
        );
        final treeBefore = await File(
          p.join(root.path, 'guide.tree'),
        ).readAsString();
        switch (change) {
          case 'changed':
            await File(
              p.join(root.path, 'topics/home.md'),
            ).writeAsString('# HOME\n');
          case 'added':
            await File(
              p.join(root.path, 'topics/added.md'),
            ).writeAsString('# Added\n[Other](other.md)\n');
          case 'removed':
            await File(p.join(root.path, 'topics/home.md')).delete();
          case 'tree':
            await File(
              p.join(root.path, 'guide.tree'),
            ).writeAsString('$treeBefore\n');
          case 'configuration':
            await File(
              p.join(root.path, 'writerside.cfg'),
            ).writeAsString('<ihp><topics dir="changed"/></ihp>');
        }
        await expectLater(
          service.apply(
            WritersideTopicRemovalRequest(
              analysis: analysis,
              updateUsagesAutomatically: true,
            ),
            project: project,
          ),
          throwsA(
            isA<BusyMarkException>().having(
              (e) => e.code,
              'code',
              'writerside.topic-file.tree-changed',
            ),
          ),
        );
        expect(await File(path).exists(), isTrue);
        if (change != 'tree') {
          expect(
            await File(p.join(root.path, 'guide.tree')).readAsString(),
            treeBefore,
          );
        }
      },
    );
  }
  for (final change in ['disk dependency', 'dirty affected buffer']) {
    test(
      'removal rejects $change after fingerprint verification and before commit',
      () async {
        final root = await syntheticProject();
        const service = WritersideTopicRemovalService();
        final path = p.join(root.path, 'topics/other.md');
        final tree = File(p.join(root.path, 'guide.tree'));
        final before = await tree.readAsString();
        final analysis = await service.analyze(
          projectRoot: root.path,
          topicPath: path,
          mode: WritersideTopicRemovalMode.safeDeleteFile,
        );
        var calls = 0;
        await expectLater(
          service.apply(
            WritersideTopicRemovalRequest(
              analysis: analysis,
              updateUsagesAutomatically: true,
            ),
            validateBeforeCommit: (paths) {
              calls++;
              if (calls != 2) return;
              if (change == 'dirty affected buffer') {
                throw const BusyMarkException(
                  'workspace.file-operation-unsaved-changes',
                );
              }
              File(
                p.join(root.path, 'topics/home.md'),
              ).writeAsStringSync('# HOME\n');
            },
          ),
          throwsA(isA<BusyMarkException>()),
        );
        expect(calls, 2);
        expect(await File(path).exists(), isTrue);
        expect(await tree.readAsString(), before);
      },
    );
  }
  test('analysis is never reused across confirmation', () async {
    final root = await syntheticProject();
    const service = WritersideTopicRemovalService();
    final path = p.join(root.path, 'topics/other.md');
    final analysis = await service.analyze(
      projectRoot: root.path,
      topicPath: path,
      mode: WritersideTopicRemovalMode.safeDeleteFile,
    );
    await File(
      p.join(root.path, 'topics/home.md'),
    ).writeAsString('# Home\n[New usage](other.md)\n');
    await expectLater(
      service.apply(
        WritersideTopicRemovalRequest(
          analysis: analysis,
          updateUsagesAutomatically: true,
        ),
      ),
      throwsA(isA<BusyMarkException>()),
    );
    expect(await File(path).exists(), isTrue);
  });
}

String? _isolateName(int _) => Isolate.current.debugName;
Never _fail(int _) => throw StateError('Worker failure');
