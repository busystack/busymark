import 'dart:async';
import 'dart:io';

import 'package:busymark/src/markdown/markdown_parser.dart';
import 'package:busymark/src/markdown/markdown_model.dart';

import 'package:busymark/src/app/app_settings.dart';
import 'package:busymark/src/core/busymark_exception.dart';
import 'package:busymark/src/core/source_span.dart';
import 'package:busymark/src/editor/wysiwyg/wysiwyg_session_state.dart';
import 'package:busymark/src/local_history/local_history_controller.dart';
import 'package:busymark/src/local_history/local_history_models.dart';
import 'package:busymark/src/local_history/local_history_store.dart';
import 'package:busymark/src/markdown/busymark_document.dart';
import 'package:busymark/src/markdown/preview_model.dart';
import 'package:busymark/src/workspace/document_buffer.dart';
import 'package:busymark/src/workspace/recovery_persistence.dart';
import 'package:busymark/src/workspace/session_persistence.dart';
import 'package:busymark/src/workspace/workspace_controller.dart';
import 'package:busymark/src/workspace/workspace_file_monitor.dart';
import 'package:busymark/src/workspace/workspace_message.dart';
import 'package:busymark/src/workspace/workspace_model.dart';
import 'package:busymark/src/workspace/workspace_service.dart';
import 'package:busymark/src/writerside/writerside_project_creator.dart';
import 'package:busymark/src/writerside/writerside_instance_service.dart';
import 'package:busymark/src/writerside/writerside_model.dart';
import 'package:busymark/src/writerside/writerside_topic_creator.dart';
import 'package:busymark/src/writerside/writerside_topic_file_editor.dart';
import 'package:busymark/src/writerside/writerside_topic_removal_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

void main() {
  test(
    'Safe Delete closes the topic buffer, selects a survivor, and records history',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'busymark-topic-removal-lifecycle-',
      );
      addTearDown(() => root.delete(recursive: true));
      await Directory(p.join(root.path, 'topics')).create();
      await File(p.join(root.path, 'writerside.cfg')).writeAsString(
        '<ihp><topics dir="topics"/><instance src="guide.tree"/></ihp>',
      );
      await File(p.join(root.path, 'guide.tree')).writeAsString('''
<instance-profile id="guide" start-page="survivor.md">
  <toc-element topic="survivor.md"/>
  <toc-element topic="doomed.md"/>
</instance-profile>
''');
      final survivor = File(p.join(root.path, 'topics', 'survivor.md'));
      final doomed = File(p.join(root.path, 'topics', 'doomed.md'));
      await survivor.writeAsString('# Survivor\n');
      await doomed.writeAsString('# Doomed\n');
      final history = MemoryLocalHistoryStore();
      final harness = await _createControllerHarness(
        localHistoryStore: history,
      );
      final controller = harness.controller._notifier;
      await controller.openPath(root.path);
      await controller.openActiveFile(survivor.path);
      await controller.openActiveFile(doomed.path);
      final analysis = await controller.analyzeWritersideTopicRemoval(
        topicPath: doomed.path,
        mode: WritersideTopicRemovalMode.safeDeleteFile,
      );

      final result = await controller.applyWritersideTopicRemoval(
        WritersideTopicRemovalRequest(analysis: analysis!),
      );

      expect(result?.deletedFile, isTrue);
      expect(doomed.existsSync(), isFalse);
      expect(
        controller.state.documentBuffers.map((buffer) => buffer.filePath),
        isNot(contains(doomed.path)),
      );
      expect(
        controller.state.workspace?.openFilePaths,
        isNot(contains(doomed.path)),
      );
      expect(controller.state.workspace?.activeFilePath, survivor.path);
      final historySnapshot = await history.load();
      final deletedDocument = historySnapshot.documents.singleWhere(
        (document) => document.historicalPaths.contains(doomed.path),
      );
      expect(deletedDocument.deleted, isTrue);
    },
  );

  test(
    'TOC writes reject an inactive dirty tree without discarding either buffer',
    () async {
      final root = await Directory.systemTemp.createTemp('busymark-toc-dirty-');
      addTearDown(() => root.delete(recursive: true));
      await Directory(p.join(root.path, 'topics')).create();
      await File(p.join(root.path, 'writerside.cfg')).writeAsString(
        '<ihp><topics dir="topics"/><instance src="g.tree"/></ihp>',
      );
      final tree = File(p.join(root.path, 'g.tree'));
      const original =
          '<instance-profile id="g" name="Guide" start-page="a.md"><toc-element topic="a.md"/></instance-profile>';
      await tree.writeAsString(original);
      final topic = File(p.join(root.path, 'topics/a.md'));
      await topic.writeAsString('# Original\n');
      final harness = await _createControllerHarness(
        fileMonitor: _ControlledFileMonitor(),
      );
      await harness.settingsController.setAutoSave(false);
      final controller = harness.controller._notifier;
      await controller.openPath(root.path);
      await controller.openActiveFile(tree.path);
      controller.updateActiveText('$original\n<!-- unsaved -->');
      await controller.openActiveFile(topic.path);
      final result = await controller.createWritersideTopic(
        const WritersideTopicCreateRequest(
          title: 'Blocked',
          fileName: 'blocked.md',
          format: WritersideTopicFormat.markdown,
        ),
        instanceTreePath: tree.path,
      );
      expect(result, isFalse);
      expect(await tree.readAsString(), original);
      expect(
        await File(p.join(root.path, 'topics/blocked.md')).exists(),
        isFalse,
      );
      expect(
        harness.controller.state.bufferForPath(tree.path)!.text,
        contains('unsaved'),
      );
      expect(
        harness.controller.state.bufferForPath(tree.path)!.isDirty,
        isTrue,
      );
      expect(harness.controller.state.activeBuffer?.filePath, topic.path);
    },
  );

  test(
    'TOC creation defers its monitor events until the new document is open',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'busymark-toc-monitor-',
      );
      addTearDown(() => root.delete(recursive: true));
      await Directory(p.join(root.path, 'topics')).create();
      await File(p.join(root.path, 'writerside.cfg')).writeAsString(
        '<ihp><topics dir="topics"/><instance src="g.tree"/></ihp>',
      );
      await File(p.join(root.path, 'g.tree')).writeAsString(
        '<instance-profile id="g" name="Guide" start-page="a.md"><toc-element topic="a.md"/></instance-profile>',
      );
      await File(
        p.join(root.path, 'topics/a.md'),
      ).writeAsString('# Original\n');
      final monitor = _ControlledFileMonitor();
      final service = _TocCreationMonitorService(monitor);
      final harness = await _createControllerHarness(
        service: service,
        fileMonitor: monitor,
      );
      await harness.controller.openPath(root.path);
      final result = await harness.controller.createWritersideTopic(
        const WritersideTopicCreateRequest(
          title: 'Created',
          fileName: 'created.md',
          format: WritersideTopicFormat.markdown,
        ),
      );
      expect(result, isTrue);
      expect(
        harness.controller.state.activeBuffer?.filePath,
        p.join(root.path, 'topics/created.md'),
      );
      expect(
        harness.controller.state.documentBuffers.map(
          (buffer) => p.basename(buffer.filePath!),
        ),
        containsAll(['a.md', 'created.md']),
      );
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(
        harness.controller.state.activeBuffer?.filePath,
        p.join(root.path, 'topics/created.md'),
      );
    },
  );

  test(
    'Markdown topic import opens its first topic in an editable buffer',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'busymark-controller-topic-import-',
      );
      final source = await Directory.systemTemp.createTemp(
        'busymark-controller-topic-source-',
      );
      addTearDown(() => root.delete(recursive: true));
      addTearDown(() => source.delete(recursive: true));
      Directory(p.join(root.path, 'topics')).createSync();
      File(p.join(root.path, 'writerside.cfg')).writeAsStringSync(
        '<ihp><topics dir="topics"/><instance src="g.tree"/></ihp>',
      );
      final tree = File(p.join(root.path, 'g.tree'))
        ..writeAsStringSync(
          '<instance-profile id="g" name="Guide" start-page="a.md">'
          '<toc-element topic="a.md"/></instance-profile>',
        );
      final original = File(p.join(root.path, 'topics', 'a.md'))
        ..writeAsStringSync('# Original\n');
      final imported = File(p.join(source.path, 'imported.md'))
        ..writeAsStringSync('# Imported\n');
      final harness = await _createControllerHarness();
      final controller = harness.controller._notifier;
      await controller.openPath(root.path);
      await controller.openActiveFile(original.path);

      final succeeded = await controller.addWritersideMarkdownTopics(
        WritersideMarkdownTopicImportRequest(
          sourceRootPath: source.path,
          selectedMarkdownPaths: [imported.path],
          treePath: tree.path,
          placement: WritersideTopicCreatePlacement.root,
        ),
      );

      final target = p.join(root.path, 'topics', 'imported.md');
      expect(succeeded, true);
      expect(controller.state.workspace?.activeFilePath, target);
      expect(controller.state.workspace?.openFilePaths, contains(target));
      expect(controller.state.activeBuffer?.filePath, target);
      expect(
        controller.state.activeBuffer?.editorState.mode,
        isNot(DocumentViewModePreference.preview),
      );
    },
  );

  test(
    'failed Markdown import preserves the active document and workspace',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'busymark-controller-topic-import-fail-',
      );
      final source = await Directory.systemTemp.createTemp(
        'busymark-controller-topic-source-',
      );
      addTearDown(() => root.delete(recursive: true));
      addTearDown(() => source.delete(recursive: true));
      Directory(p.join(root.path, 'topics')).createSync();
      File(p.join(root.path, 'writerside.cfg')).writeAsStringSync(
        '<ihp><topics dir="topics"/><instance src="g.tree"/></ihp>',
      );
      final tree = File(p.join(root.path, 'g.tree'))
        ..writeAsStringSync(
          '<instance-profile id="g" name="Guide" start-page="a.md">'
          '<toc-element topic="a.md"/></instance-profile>',
        );
      final original = File(p.join(root.path, 'topics', 'a.md'))
        ..writeAsStringSync('# Original\n');
      final conflict = File(p.join(source.path, 'a.md'))
        ..writeAsStringSync('# Conflict\n');
      final harness = await _createControllerHarness();
      final controller = harness.controller._notifier;
      await controller.openPath(root.path);
      await controller.openActiveFile(original.path);
      final originalTree = tree.readAsStringSync();

      final succeeded = await controller.addWritersideMarkdownTopics(
        WritersideMarkdownTopicImportRequest(
          sourceRootPath: source.path,
          selectedMarkdownPaths: [conflict.path],
          treePath: tree.path,
          placement: WritersideTopicCreatePlacement.root,
        ),
      );

      expect(succeeded, false);
      expect(controller.state.workspace?.activeFilePath, original.path);
      expect(controller.state.activeBuffer?.filePath, original.path);
      expect(original.readAsStringSync(), '# Original\n');
      expect(tree.readAsStringSync(), originalTree);
    },
  );

  test('Validate publishes a valid table containing an escaped pipe', () async {
    final root = await Directory.systemTemp.createTemp(
      'busymark-table-validation-',
    );
    addTearDown(() => root.delete(recursive: true));
    final file = File(p.join(root.path, 'table.md'));
    await file.writeAsString('# Table\n');
    final harness = await _createControllerHarness();
    await harness.settingsController.setValidateOnEdit(false);
    await harness.settingsController.setAutoSave(false);
    final controller = harness.controller._notifier;
    await controller.openPath(file.path);
    const source =
        '| One | Two | Three |\n| --- | --- | --- |\n'
        r'| a\|b | a|b |'
        '\n';
    controller.updateActiveText(source);
    final result = await controller.validateActive();
    expect(result.status, ValidationStatus.published);
    expect(controller.isCurrentValidation(result), isTrue);
    expect(harness.controller.state.workspace!.markdown!.source, source);
    expect(harness.controller.state.workspace!.diagnostics, isEmpty);
  });

  test(
    'validation reports stale, busy and failed outcomes without publishing old results',
    () async {
      final service = _DelayedValidationWorkspaceService();
      final harness = await _createControllerHarness(service: service);
      final controller = harness.controller._notifier;
      await harness.settingsController.setValidateOnEdit(false);
      await controller.openPath(service.rootPath);
      controller.updateActiveWysiwygText(
        '# Dirty A\n',
        document: const MarkdownParser()
            .parse(filePath: service.aPath, source: '# Dirty A\n')
            .busyDocument,
      );
      final pending = controller.validateActive();
      await service.validationStarted.future;
      expect((await controller.validateActive()).status, ValidationStatus.busy);
      await controller.openActiveFile(service.bPath);
      service.finishValidation();
      final outcome = await pending;
      expect(outcome.status, ValidationStatus.stale);
      expect(outcome.filePath, service.aPath);
      expect(controller.isCurrentValidation(outcome), isFalse);
      service.failValidation = true;
      final failed = await controller.validateActive();
      expect(failed.status, ValidationStatus.failed);
      expect(failed.published, isFalse);
      expect(
        harness.controller.state.message?.code,
        WorkspaceMessageCode.validationFailed,
      );
    },
  );

  for (final clearDuringValidation in [false, true]) {
    test(
      'validation preserves the latest runtime diagnostic change: clear=$clearDuringValidation',
      () async {
        final service = _DelayedValidationWorkspaceService();
        final harness = await _createControllerHarness(service: service);
        final controller = harness.controller._notifier;
        await harness.settingsController.setValidateOnEdit(false);
        await controller.openPath(service.rootPath);
        controller.updateActiveWysiwygText(
          '# Dirty A\n',
          document: const MarkdownParser()
              .parse(filePath: service.aPath, source: '# Dirty A\n')
              .busyDocument,
        );
        if (clearDuringValidation) {
          controller.updateMathRenderDiagnostic(
            expressionId: 'math',
            code: 'math.invalid',
          );
        }
        final pending = controller.validateActive();
        await service.validationStarted.future;
        controller.updateMathRenderDiagnostic(
          expressionId: 'math',
          code: clearDuringValidation ? null : 'math.invalid',
        );
        service.finishValidation();
        final outcome = await pending;
        expect(outcome.status, ValidationStatus.published);
        expect(
          outcome.revision,
          harness.controller.state.activeBuffer!.revision,
        );
        expect(controller.isCurrentValidation(outcome), isTrue);
        expect(
          harness.controller.state.workspace!.runtimeDiagnostics,
          hasLength(clearDuringValidation ? 0 : 1),
        );
      },
    );
  }

  test(
    'math callbacks from an older editor revision cannot republish errors',
    () async {
      final harness = await _createControllerHarness();
      final controller = harness.controller._notifier;
      await harness.settingsController.setValidateOnEdit(false);
      await controller.openPath('test/fixtures/markdown/basic.md');
      final revision = controller.editRevision;
      final path = harness.controller.state.workspace!.activeFilePath;
      controller.updateActiveText('# Changed\n');
      controller.updateMathRenderDiagnostic(
        expressionId: 'old',
        code: 'math.invalidTex',
        expectedRevision: revision,
        expectedFilePath: path,
      );
      expect(harness.controller.state.workspace!.runtimeDiagnostics, isEmpty);
    },
  );

  test('Markdown validation uses the unsaved linked tab snapshot', () async {
    final root = await Directory.systemTemp.createTemp('busymark-dirty-links-');
    addTearDown(() => root.delete(recursive: true));
    final a = File(p.join(root.path, 'a.md'));
    final b = File(p.join(root.path, 'b.md'));
    await a.writeAsString('# A\n[target](b.md#dirty)\n');
    await b.writeAsString('# Saved\n');
    final harness = await _createControllerHarness();
    await harness.settingsController.setValidateOnEdit(false);
    await harness.settingsController.setAutoSave(false);
    final controller = harness.controller._notifier;
    await controller.openPath(root.path);
    await controller.openActiveFile(b.path);
    controller.updateActiveText('# Dirty\n');
    await controller.openActiveFile(a.path);
    final outcome = await controller.validateActive();
    expect(outcome.status, ValidationStatus.published);
    expect(
      harness.controller.state.workspace!.diagnostics.where(
        (d) => d.filePath == a.path,
      ),
      isEmpty,
    );
    expect(await b.readAsString(), '# Saved\n');
  });

  for (final savedAnchor in [true, false]) {
    test('discarding an inactive Writerside tab restores disk dependencies: '
        'savedAnchor=$savedAnchor', () async {
      final root = await Directory.systemTemp.createTemp(
        'busymark-discard-validation-',
      );
      addTearDown(() => root.delete(recursive: true));
      String target(bool anchor) =>
          '<topic id="b" title="B"><p'
          '${anchor ? ' id="part"' : ''}>Target</p></topic>';
      for (final entry in {
        'writerside.cfg':
            '<ihp><module name="docs"/><topics dir="topics"/></ihp>',
        'topics/a.topic':
            '<topic id="a" title="A"><a href="b.topic#part"/></topic>',
        'topics/b.topic': target(savedAnchor),
      }.entries) {
        final file = File(p.join(root.path, entry.key));
        await file.parent.create(recursive: true);
        await file.writeAsString(entry.value);
      }
      final harness = await _createControllerHarness();
      await harness.settingsController.setValidateOnEdit(false);
      await harness.settingsController.setAutoSave(false);
      final controller = harness.controller._notifier;
      final aPath = p.join(root.path, 'topics/a.topic');
      final bPath = p.join(root.path, 'topics/b.topic');
      await controller.openPath(root.path);
      await controller.openActiveFile(bPath);
      final bId = harness.controller.state.activeBuffer!.id;
      controller.updateActiveText(target(!savedAnchor));
      expect((await controller.validateActive()).published, isTrue);
      await controller.openActiveFile(aPath);
      expect((await controller.validateActive()).published, isTrue);
      Iterable<Object> linkErrors() =>
          harness.controller.state.workspace!.diagnostics.where(
            (d) =>
                d.filePath == aPath && d.code == 'writerside.link.unavailable',
          );
      expect(linkErrors(), hasLength(savedAnchor ? 1 : 0));
      expect(await controller.closeDocumentBuffer(bId, discard: true), isTrue);
      expect(harness.controller.state.bufferForPath(bPath), isNull);
      expect((await controller.validateActive()).published, isTrue);
      expect(linkErrors(), hasLength(savedAnchor ? 0 : 1));
      expect(
        harness.controller.state.workspace!.writersideModule!.sourceOverrides,
        isNot(contains(bPath)),
      );
      expect(await File(bPath).readAsString(), target(savedAnchor));
    });
  }

  test(
    'Writerside rename stages verified edits across unsaved tabs with undo',
    () async {
      final root = await Directory.systemTemp.createTemp('busymark-rename-');
      addTearDown(() => root.delete(recursive: true));
      for (final entry in {
        'writerside.cfg':
            '<ihp><module name="docs"/><topics dir="topics"/><instance src="guide.tree"/></ihp>',
        'guide.tree':
            '<instance-profile id="guide" name="Guide" start-page="a.topic"><toc-element topic="a.topic"/></instance-profile>',
        'topics/a.topic':
            '<topic id="a" title="A"><p id="anchor">Original</p></topic>',
        'topics/b.topic':
            '<topic id="b" title="B"><a href="a.topic#anchor"/></topic>',
      }.entries) {
        final file = File(p.join(root.path, entry.key));
        await file.parent.create(recursive: true);
        await file.writeAsString(entry.value);
      }
      final harness = await _createControllerHarness();
      final controller = harness.controller._notifier;
      await controller.openPath(root.path);
      final aPath = p.join(root.path, 'topics/a.topic');
      final bPath = p.join(root.path, 'topics/b.topic');
      await controller.openActiveFile(bPath);
      controller.updateActiveText(
        '<topic id="b" title="B"><p>Unsaved</p><a href="a.topic#anchor"/></topic>',
        sourceFilePath: bPath,
      );
      await controller.openActiveFile(aPath);
      final index = (await controller.writersideEditorIndex())!;
      final symbol = index
          .definitions('a.topic#anchor', moduleId: 'docs')
          .single;
      final edits = index.safeRenameEdits(symbol, 'renamed');
      expect(await controller.applyWritersideRename(edits), isTrue);
      final state = harness.controller.state;
      expect(
        state.documentBuffers
            .singleWhere((buffer) => buffer.filePath == bPath)
            .text,
        '<topic id="b" title="B"><p>Unsaved</p><a href="a.topic#renamed"/></topic>',
      );
      expect(
        state.documentBuffers.where((buffer) => buffer.dirty),
        hasLength(2),
      );
      expect(await File(bPath).readAsString(), isNot(contains('renamed')));
      expect(controller.undoActiveBuffer(), isTrue);
      expect(harness.controller.state.activeText, contains('id="anchor"'));
      expect(await controller.applyWritersideRename(edits), isFalse);
    },
  );

  test(
    'records opened Markdown files by file path in recent workspaces',
    () async {
      final harness = await _createControllerHarness();
      final settingsController = harness.settingsController;
      final controller = harness.controller;

      await controller.openPath('test/fixtures/markdown/basic.md');

      expect(controller.state.workspace?.kind, WorkspaceKind.singleMarkdown);
      expect(
        settingsController.state.recentWorkspaces.first.path,
        endsWith('test/fixtures/markdown/basic.md'),
      );
      expect(
        settingsController.state.recentWorkspaces.first.kind,
        'singleMarkdown',
      );

      controller.dispose();
      settingsController.dispose();
    },
  );

  test('records opened folders by folder path in recent workspaces', () async {
    final harness = await _createControllerHarness();
    final settingsController = harness.settingsController;
    final controller = harness.controller;

    await controller.openPath('test/fixtures/markdown');

    expect(controller.state.workspace?.kind, WorkspaceKind.markdownFolder);
    expect(
      settingsController.state.recentWorkspaces.first.path,
      endsWith('test/fixtures/markdown'),
    );
    expect(
      settingsController.state.recentWorkspaces.first.kind,
      'markdownFolder',
    );

    controller.dispose();
    settingsController.dispose();
  });

  test(
    'workspace file operations refresh and preserve active moved files',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'busymark-file-ops-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final first = File(p.join(directory.path, 'first.md'))
        ..writeAsStringSync('# First\n');
      final docs = Directory(p.join(directory.path, 'docs'))..createSync();
      File(p.join(docs.path, 'existing.md')).writeAsStringSync('# Existing\n');
      final harness = await _createControllerHarness();
      final settingsController = harness.settingsController;
      final controller = harness.controller;

      await controller.openPath(directory.path);
      await settingsController.setDocumentViewMode(
        DocumentViewModePreference.preview,
      );

      final created = p.join(directory.path, 'new.md');
      expect(
        await controller.createWorkspaceFile(directory.path, 'new.md'),
        isTrue,
      );
      expect(File(created).existsSync(), isTrue);
      expect(controller.state.workspace?.activeFilePath, created);
      expect(
        settingsController.state.documentViewMode,
        DocumentViewModePreference.editor,
      );

      final renamed = p.join(directory.path, 'renamed.md');
      expect(
        await controller.renameWorkspaceEntity(created, 'renamed.md'),
        isTrue,
      );
      expect(File(created).existsSync(), isFalse);
      expect(File(renamed).existsSync(), isTrue);
      expect(controller.state.workspace?.activeFilePath, renamed);

      final moved = p.join(docs.path, 'renamed.md');
      expect(await controller.moveWorkspaceEntity(renamed, docs.path), isTrue);
      expect(File(renamed).existsSync(), isFalse);
      expect(File(moved).existsSync(), isTrue);
      expect(controller.state.workspace?.activeFilePath, moved);

      expect(await controller.deleteWorkspaceEntity(moved), isTrue);
      expect(File(moved).existsSync(), isFalse);
      expect(controller.state.workspace?.activeFilePath, isNot(moved));
      expect([
        first.path,
        p.join(docs.path, 'existing.md'),
      ], contains(controller.state.workspace?.activeFilePath));

      controller.dispose();
      settingsController.dispose();
    },
  );

  test(
    'creates an unsaved Markdown file without adding it to recent',
    () async {
      final harness = await _createControllerHarness();
      final settingsController = harness.settingsController;
      final controller = harness.controller;

      await controller.createMarkdownFile();

      expect(controller.state.workspace?.kind, WorkspaceKind.untitledMarkdown);
      expect(controller.state.workspace?.activeFilePath, isNull);
      expect(controller.state.workspace?.markdown?.filePath, isEmpty);
      expect(controller.state.isDirty, isTrue);
      expect(settingsController.state.recentWorkspaces, isEmpty);

      controller.dispose();
      settingsController.dispose();
    },
  );

  test(
    'creates CommonMark inside Writerside without replacing project or dirty topic',
    () async {
      final service = _RecordingDocumentSourcesWorkspaceService();
      final harness = await _createControllerHarness(service: service);
      final controller = harness.controller._notifier;
      await controller.openPath('test/fixtures/writerside/basic_project');
      final originalWorkspace = controller.state.workspace!;
      final topic = controller.state.activeBuffer!;
      final dirtyTopicText = '${topic.text}\nUnsaved Writerside edit.\n';
      controller.updateActiveText(dirtyTopicText);

      await controller.createMarkdownFile();
      final untitled = controller.state.activeBuffer!;
      const markdown = '''# Draft heading

Paragraph with *emphasis*.

- one
- two

```text
code
```
''';
      controller.updateActiveText(markdown);
      await _waitFor(
        () =>
            controller.state.preview?.blocks.any(
              (block) =>
                  block.kind == PreviewBlockKind.heading &&
                  block.text == 'Draft heading',
            ) ??
            false,
      );

      final currentWorkspace = controller.state.workspace!;
      final resolved = resolveWorkspaceDocumentContext(
        currentWorkspace,
        controller.state.activeBuffer!,
      );
      expect(currentWorkspace.id, originalWorkspace.id);
      expect(currentWorkspace.kind, WorkspaceKind.writersideModule);
      expect(currentWorkspace.writersideProject, isNotNull);
      expect(currentWorkspace.writersideModule, isNotNull);
      expect(currentWorkspace.activeFilePath, isNull);
      expect(untitled.id, isNot(topic.id));
      expect(resolved.kind, DocumentKind.markdown);
      expect(resolved.markdownMode, MarkdownMode.commonMark);
      expect(currentWorkspace.markdown?.mode, MarkdownMode.commonMark);
      expect(currentWorkspace.markdown?.source, markdown);
      expect(
        controller.state.preview!.blocks.map((block) => block.kind),
        containsAll(<PreviewBlockKind>[
          PreviewBlockKind.heading,
          PreviewBlockKind.paragraph,
          PreviewBlockKind.list,
          PreviewBlockKind.code,
        ]),
      );
      final preservedTopic = controller.state.documentBuffers.singleWhere(
        (buffer) => buffer.id == topic.id,
      );
      expect(preservedTopic.text, dirtyTopicText);
      expect(preservedTopic.isDirty, isTrue);
      expect(service.lastSources[topic.filePath], dirtyTopicText);
      expect(service.lastSources.keys, isNot(contains('')));
      expect(service.lastSources, hasLength(1));

      expect(await controller.activateDocumentBuffer(topic.id), isTrue);
      expect(controller.state.activeText, dirtyTopicText);
      expect(await controller.activateDocumentBuffer(untitled.id), isTrue);
      expect(controller.state.activeText, markdown);
      expect(
        controller.state.workspace?.markdown?.mode,
        MarkdownMode.commonMark,
      );
      expect(
        controller.state.preview?.blocks.any(
          (block) => block.text == 'Draft heading',
        ),
        isTrue,
      );
    },
  );

  test('identical untitled buffers remain distinct by buffer id', () async {
    final harness = await _createControllerHarness();
    final controller = harness.controller._notifier;
    await controller.openPath('test/fixtures/writerside/basic_project');
    const source = '# Same heading\n\nSame text.\n';

    await controller.createMarkdownFile();
    controller.updateActiveText(source);
    final first = controller.state.activeBuffer!;
    controller.updateDocumentEditorState(
      first.id,
      first.editorState.copyWith(
        selection: const TextSelection.collapsed(offset: 2),
      ),
    );
    await controller.createMarkdownFile();
    controller.updateActiveText(source);
    final second = controller.state.activeBuffer!;
    controller.updateDocumentEditorState(
      second.id,
      second.editorState.copyWith(
        selection: const TextSelection.collapsed(offset: 7),
      ),
    );

    expect(first.id, isNot(second.id));
    expect(first.filePath, isNull);
    expect(second.filePath, isNull);
    expect(await controller.activateDocumentBuffer(first.id), isTrue);
    expect(controller.state.activeBuffer?.id, first.id);
    expect(controller.state.activeBuffer?.editorState.selection.baseOffset, 2);
    expect(await controller.activateDocumentBuffer(second.id), isTrue);
    expect(controller.state.activeBuffer?.id, second.id);
    expect(controller.state.activeBuffer?.editorState.selection.baseOffset, 7);
    expect(controller.state.workspace?.markdown?.source, source);
    expect(
      controller.state.preview?.blocks
          .singleWhere((block) => block.kind == PreviewBlockKind.heading)
          .text,
      'Same heading',
    );
  });

  test(
    'delayed untitled preview cannot publish into another untitled tab',
    (() async {
      final service = _BlockingUntitledPreviewWorkspaceService();
      final harness = await _createControllerHarness(service: service);
      await harness.settingsController.setValidateOnEdit(false);
      final controller = harness.controller._notifier;
      await controller.openPath('test/fixtures/writerside/basic_project');
      await controller.createMarkdownFile();
      final firstId = controller.state.activeBuffer!.id;
      service.blockNext(firstId);
      controller.updateActiveText('# First delayed\n');
      await service.started.future;

      await controller.createMarkdownFile();
      final secondId = controller.state.activeBuffer!.id;
      controller.updateActiveText('# Second current\n');
      service.release();
      await service.finished.future;
      await _waitFor(
        () =>
            controller.state.preview?.blocks.any(
              (block) => block.text == 'Second current',
            ) ??
            false,
      );

      expect(secondId, isNot(firstId));
      expect(controller.state.activeBuffer?.id, secondId);
      expect(controller.state.activeText, '# Second current\n');
      expect(
        controller.state.preview?.blocks.any(
          (block) => block.text == 'First delayed',
        ),
        isFalse,
      );
    }),
  );

  test('new Markdown files leave preview mode for editor mode', () async {
    final harness = await _createControllerHarness();
    final settingsController = harness.settingsController;
    final controller = harness.controller;

    await settingsController.setDocumentViewMode(
      DocumentViewModePreference.preview,
    );
    await controller.createMarkdownFile();

    expect(
      settingsController.state.documentViewMode,
      DocumentViewModePreference.editor,
    );

    controller.dispose();
    settingsController.dispose();
  });

  test('new Markdown files preserve non-preview view modes', () async {
    for (final mode in <DocumentViewModePreference>[
      DocumentViewModePreference.editor,
      DocumentViewModePreference.source,
      DocumentViewModePreference.split,
    ]) {
      final harness = await _createControllerHarness();
      final settingsController = harness.settingsController;
      final controller = harness.controller;

      await settingsController.setDocumentViewMode(mode);
      await controller.createMarkdownFile();

      expect(settingsController.state.documentViewMode, mode);

      controller.dispose();
      settingsController.dispose();
    }
  });

  test('discarding an untitled Markdown file clears the workspace', () async {
    final harness = await _createControllerHarness();
    final settingsController = harness.settingsController;
    final controller = harness.controller;

    await controller.createMarkdownFile();
    controller.updateActiveText('# Draft\n');

    expect(await controller.discardActiveChanges(), isTrue);
    expect(controller.state.workspace, isNull);
    expect(controller.state.activeText, isEmpty);
    expect(controller.state.isDirty, isFalse);

    controller.dispose();
    settingsController.dispose();
  });

  test(
    'discarding a saved file reloads disk text and clears dirty state',
    () async {
      final harness = await _createControllerHarness();
      final settingsController = harness.settingsController;
      final controller = harness.controller;

      await controller.openPath('test/fixtures/markdown/basic.md');
      final savedText = controller.state.activeText;
      controller.updateActiveText('# Dirty\n');

      expect(await controller.discardActiveChanges(), isTrue);
      expect(controller.state.activeText, savedText);
      expect(controller.state.isDirty, isFalse);
      expect(controller.state.workspace?.activeFileSnapshot, isNotNull);

      controller.dispose();
      settingsController.dispose();
    },
  );

  test('creates a Writerside project and records it as recent', () async {
    final parent = await Directory.systemTemp.createTemp(
      'busymark-controller-create-',
    );
    final harness = await _createControllerHarness();
    final settingsController = harness.settingsController;
    final controller = harness.controller;

    final created = await controller.createWritersideProject(
      WritersideProjectCreateRequest(
        parentDirectoryPath: parent.path,
        projectName: 'Docs',
        directoryName: 'docs',
        instanceName: 'User Guide',
        topicTitle: 'Getting started',
      ),
    );

    final rootPath = p.join(parent.path, 'docs');
    expect(created, isTrue);
    expect(controller.state.workspace?.kind, WorkspaceKind.writersideModule);
    expect(controller.state.activeText, contains('# Getting started'));
    expect(controller.state.preview, isNotNull);
    expect(settingsController.state.recentWorkspaces.first.path, rootPath);
    expect(
      settingsController.state.recentWorkspaces.first.kind,
      'writersideModule',
    );

    controller.dispose();
    settingsController.dispose();
    await parent.delete(recursive: true);
  });

  test(
    'creates a Writerside topic and opens it without changing recents',
    () async {
      final parent = await Directory.systemTemp.createTemp(
        'busymark-controller-create-topic-',
      );
      final harness = await _createControllerHarness();
      final settingsController = harness.settingsController;
      final controller = harness.controller;
      await controller.createWritersideProject(
        WritersideProjectCreateRequest(
          parentDirectoryPath: parent.path,
          projectName: 'Docs',
          directoryName: 'docs',
          instanceName: 'User Guide',
          topicTitle: 'Getting started',
        ),
      );
      final recentCount = settingsController.state.recentWorkspaces.length;

      final created = await controller.createWritersideTopic(
        const WritersideTopicCreateRequest(
          title: 'API Reference',
          fileName: 'api-reference.md',
        ),
      );

      final topicPath = p.join(
        parent.path,
        'docs',
        'topics',
        'api-reference.md',
      );
      expect(created, isTrue);
      expect(controller.state.workspace?.activeFilePath, topicPath);
      expect(controller.state.activeText, contains('# API Reference'));
      expect(controller.state.preview, isNotNull);
      expect(settingsController.state.recentWorkspaces, hasLength(recentCount));

      controller.dispose();
      settingsController.dispose();
      await parent.delete(recursive: true);
    },
  );

  test(
    'topic TOC actions refresh the workspace and preserve file state',
    () async {
      final parent = await Directory.systemTemp.createTemp(
        'busymark-controller-topic-actions-',
      );
      final harness = await _createControllerHarness();
      final settingsController = harness.settingsController;
      final controller = harness.controller;
      await controller.createWritersideProject(
        WritersideProjectCreateRequest(
          parentDirectoryPath: parent.path,
          projectName: 'Docs',
          directoryName: 'docs',
          instanceName: 'User Guide',
          topicTitle: 'Getting started',
        ),
      );
      await controller.createWritersideTopic(
        const WritersideTopicCreateRequest(
          title: 'Secondary',
          fileName: 'secondary.md',
        ),
      );
      final rootPath = p.join(parent.path, 'docs');
      final treePath = p.join(rootPath, 'user-guide.tree');
      final startPath = p.join(rootPath, 'topics', 'getting-started.md');
      final secondaryPath = p.join(rootPath, 'topics', 'secondary.md');
      expect(await controller.openActiveFile(startPath), isTrue);
      expect(
        controller.state.workspace?.openFilePaths,
        contains(secondaryPath),
      );

      expect(
        await controller.moveWritersideTocEntry(
          treePath: treePath,
          sourcePath: const [1],
          placement: WritersideTopicCreatePlacement.child,
          referencePath: const [0],
        ),
        isTrue,
      );
      var tree = XmlDocument.parse(File(treePath).readAsStringSync());
      var first = tree.rootElement.childElements
          .where((element) => element.name.local == 'toc-element')
          .first;
      expect(first.childElements.single.getAttribute('topic'), 'secondary.md');
      expect(controller.state.workspace?.activeFilePath, startPath);

      final renamePlan = await controller.prepareWritersideTopicRename(
        secondaryPath,
        'renamed.md',
        topicModuleRoot: rootPath,
      );
      expect(renamePlan, isNotNull);
      expect(File(secondaryPath).existsSync(), isTrue);
      expect(
        File(p.join(rootPath, 'topics', 'renamed.md')).existsSync(),
        isFalse,
      );
      expect(await controller.applyWritersideTopicRename(renamePlan!), isTrue);
      final renamedPath = p.join(rootPath, 'topics', 'renamed.md');
      tree = XmlDocument.parse(File(treePath).readAsStringSync());
      first = tree.rootElement.childElements
          .where((element) => element.name.local == 'toc-element')
          .first;
      expect(first.childElements.single.getAttribute('topic'), 'renamed.md');
      expect(controller.state.workspace?.activeFilePath, startPath);
      expect(controller.state.workspace?.openFilePaths, contains(renamedPath));
      expect(
        controller.state.workspace?.openFilePaths,
        isNot(contains(secondaryPath)),
      );
      expect(File(renamedPath).existsSync(), isTrue);

      expect(
        await controller.removeWritersideTocEntry(
          treePath: treePath,
          nodePath: const [0, 0],
        ),
        isTrue,
      );
      expect(File(renamedPath).existsSync(), isTrue);
      expect(File(treePath).readAsStringSync(), isNot(contains('renamed.md')));

      expect(await controller.deleteWritersideTopicFile(renamedPath), isTrue);
      expect(File(renamedPath).existsSync(), isFalse);

      controller.dispose();
      settingsController.dispose();
      await parent.delete(recursive: true);
    },
  );

  test(
    'reviewed topic rename is rejected after a project buffer becomes dirty',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'busymark-controller-stale-topic-preview-',
      );
      addTearDown(() => root.delete(recursive: true));
      await Directory(p.join(root.path, 'topics')).create();
      await File(p.join(root.path, 'writerside.cfg')).writeAsString(
        '<ihp><topics dir="topics"/><instance src="guide.tree"/></ihp>',
      );
      final tree = File(p.join(root.path, 'guide.tree'));
      const treeSource =
          '<instance-profile id="guide" start-page="guide.md"><toc-element topic="guide.md"/><toc-element topic="notes.md"/></instance-profile>';
      await tree.writeAsString(treeSource);
      final guide = File(p.join(root.path, 'topics', 'guide.md'));
      final notes = File(p.join(root.path, 'topics', 'notes.md'));
      await guide.writeAsString('# Guide\n');
      await notes.writeAsString('# Notes\n');
      final harness = await _createControllerHarness(
        fileMonitor: _ControlledFileMonitor(),
      );
      await harness.settingsController.setAutoSave(false);
      final controller = harness.controller._notifier;
      await controller.openPath(root.path);
      final plan = await controller.prepareWritersideTopicRename(
        guide.path,
        'setup.md',
        topicModuleRoot: root.path,
      );
      expect(plan, isNotNull);
      await controller.openActiveFile(notes.path);
      controller.updateActiveText('# Notes\n\nNew unsaved project content.\n');

      expect(await controller.applyWritersideTopicRename(plan!), isFalse);

      expect(await guide.readAsString(), '# Guide\n');
      expect(await notes.readAsString(), '# Notes\n');
      expect(await tree.readAsString(), treeSource);
      expect(
        await File(p.join(root.path, 'topics', 'setup.md')).exists(),
        isFalse,
      );
      expect(
        (harness.controller.state.message!.error as BusyMarkException).code,
        'writerside.topic-file.project-buffers-dirty',
      );
    },
  );

  test('save as writes a new Markdown file and records it as recent', () async {
    final directory = await Directory.systemTemp.createTemp(
      'busymark-save-as-',
    );
    final file = File('${directory.path}/created.md');
    final harness = await _createControllerHarness();
    final settingsController = harness.settingsController;
    final controller = harness.controller;

    await controller.createMarkdownFile();
    controller.updateActiveText('# Created\n\nDraft text.');

    expect(await controller.saveActiveAs(file.path), isTrue);
    expect(await file.readAsString(), '# Created\n\nDraft text.');
    expect(controller.state.workspace?.kind, WorkspaceKind.singleMarkdown);
    expect(controller.state.workspace?.activeFilePath, file.path);
    expect(controller.state.isDirty, isFalse);
    expect(settingsController.state.recentWorkspaces.first.path, file.path);

    controller.dispose();
    settingsController.dispose();
    await directory.delete(recursive: true);
  });

  test(
    'saving untitled Markdown in Writerside keeps ordinary files CommonMark',
    (() async {
      final root = await _createWritableWritersideFixture('ordinary-save');
      addTearDown(() => root.delete(recursive: true));
      final harness = await _createControllerHarness();
      final controller = harness.controller._notifier;
      await controller.openPath(root.path);
      await controller.createMarkdownFile();
      final bufferId = controller.state.activeBuffer!.id;
      controller.updateActiveText('# Ordinary saved note\n');
      final destination = p.join(root.path, 'notes.md');

      expect(await controller.saveActiveAs(destination), isTrue);

      final state = controller.state;
      expect(state.workspace?.kind, WorkspaceKind.writersideModule);
      expect(state.activeBuffer?.id, bufferId);
      expect(state.activeBuffer?.filePath, destination);
      final resolved = resolveWorkspaceDocumentContext(
        state.workspace!,
        state.activeBuffer!,
      );
      expect(resolved.kind, DocumentKind.markdown);
      expect(resolved.markdownMode, MarkdownMode.commonMark);
      expect(state.workspace?.markdown?.mode, MarkdownMode.commonMark);
    }),
  );

  test(
    'Writerside refresh preserves saved Markdown outside the workspace root',
    (() async {
      final root = await _createWritableWritersideFixture('external-save');
      final external = await Directory.systemTemp.createTemp(
        'busymark-writerside-external-note-',
      );
      addTearDown(() => root.delete(recursive: true));
      addTearDown(() => external.delete(recursive: true));
      final harness = await _createControllerHarness();
      final controller = harness.controller;
      await controller.openPath(root.path);
      await controller.createMarkdownFile();
      final bufferId = controller.state.activeBuffer!.id;
      const source = '''# External note

CommonMark paragraph.

- remains open
''';
      controller.updateActiveText(source);
      final destination = p.join(external.path, 'note.md');

      expect(await controller.saveActiveAs(destination), isTrue);
      expect(
        controller.state.workspace!.files.any(
          (file) => file.absolutePath == destination,
        ),
        isFalse,
      );
      expect(await controller.refreshWorkspaceFromDisk(), isTrue);

      final state = controller.state;
      final buffer = state.documentBuffers.singleWhere(
        (candidate) => candidate.id == bufferId,
      );
      expect(state.workspace?.kind, WorkspaceKind.writersideModule);
      expect(state.activeBuffer?.id, bufferId);
      expect(buffer.filePath, destination);
      expect(buffer.diskState, DocumentDiskState.present);
      expect(buffer.text, source);
      expect(state.activeText, source);
      final resolved = resolveWorkspaceDocumentContext(
        state.workspace!,
        buffer,
      );
      expect(resolved.kind, DocumentKind.markdown);
      expect(resolved.markdownMode, MarkdownMode.commonMark);
      expect(state.workspace?.markdown?.mode, MarkdownMode.commonMark);
      expect(state.workspace?.markdown?.source, source);
      expect(
        state.preview?.blocks.map((block) => block.kind),
        containsAll(<PreviewBlockKind>[
          PreviewBlockKind.heading,
          PreviewBlockKind.paragraph,
          PreviewBlockKind.list,
        ]),
      );
    }),
  );

  test(
    'saving untitled Markdown into discovered topics reclassifies it',
    (() async {
      final root = await _createWritableWritersideFixture('topic-save');
      addTearDown(() => root.delete(recursive: true));
      final harness = await _createControllerHarness();
      final controller = harness.controller._notifier;
      await controller.openPath(root.path);
      await controller.createMarkdownFile();
      final bufferId = controller.state.activeBuffer!.id;
      controller.updateActiveText('# Newly discovered topic\n');
      final destination = p.join(root.path, 'topics', 'new-topic.md');

      expect(await controller.saveActiveAs(destination), isTrue);

      final state = controller.state;
      expect(state.workspace?.kind, WorkspaceKind.writersideModule);
      expect(state.activeBuffer?.id, bufferId);
      expect(state.activeBuffer?.filePath, destination);
      final resolved = resolveWorkspaceDocumentContext(
        state.workspace!,
        state.activeBuffer!,
      );
      expect(resolved.kind, DocumentKind.writersideMarkdownTopic);
      expect(resolved.markdownMode, MarkdownMode.writersideMarkdown);
      expect(state.workspace?.markdown?.mode, MarkdownMode.writersideMarkdown);
    }),
  );

  test(
    'saving multiple untitled documents creates normal file buffers',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'busymark-multiple-untitled-',
      );
      final firstFile = File(p.join(directory.path, 'first.md'));
      final secondFile = File(p.join(directory.path, 'second.md'));
      final harness = await _createControllerHarness();
      final settingsController = harness.settingsController;
      final controller = harness.controller;

      await controller.createMarkdownFile();
      controller.updateActiveText('# First draft\n');
      await controller.createMarkdownFile();
      controller.updateActiveText('# Second draft\n');
      expect(controller.state.documentBuffers, hasLength(2));

      expect(await controller.saveActiveAs(secondFile.path), isTrue);
      expect(controller.state.workspace?.kind, WorkspaceKind.singleMarkdown);
      expect(controller.state.activeBuffer?.filePath, secondFile.path);
      controller.updateActiveText('# Second saved again\n');
      expect(await controller.saveActive(), isTrue);
      expect(await secondFile.readAsString(), '# Second saved again\n');

      expect(await controller.activatePreviousOpenFileTab(), isTrue);
      expect(controller.state.activeBuffer?.filePath, isNull);
      expect(await controller.saveActiveAs(firstFile.path), isTrue);
      expect(controller.state.documentBuffers, hasLength(2));
      expect(
        controller.state.documentBuffers.map((buffer) => buffer.filePath),
        containsAll([firstFile.path, secondFile.path]),
      );

      final firstId = controller.state.activeBuffer!.id;
      expect(await controller.closeDocumentBuffer(firstId), isTrue);
      expect(controller.state.documentBuffers, hasLength(1));
      final secondId = controller.state.activeBuffer!.id;
      expect(await controller.closeDocumentBuffer(secondId), isTrue);
      expect(controller.state.documentBuffers, isEmpty);

      controller.dispose();
      settingsController.dispose();
      await directory.delete(recursive: true);
    },
  );

  test(
    'save as refuses an existing file unless overwrite is explicit',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'busymark-save-as-existing-',
      );
      final file = File('${directory.path}/existing.md');
      await file.writeAsString('# Existing\n');
      final harness = await _createControllerHarness();
      final settingsController = harness.settingsController;
      final controller = harness.controller;

      await controller.createMarkdownFile();
      controller.updateActiveText('# Draft\n');

      expect(await controller.saveActiveAs(file.path), isFalse);
      expect(await file.readAsString(), '# Existing\n');
      expect(controller.state.workspace?.kind, WorkspaceKind.untitledMarkdown);
      expect(controller.state.isDirty, isTrue);
      expect(controller.state.message?.code, WorkspaceMessageCode.saveFailed);

      expect(
        await controller.saveActiveAs(file.path, overwriteExisting: true),
        isTrue,
      );
      expect(await file.readAsString(), '# Draft\n');

      controller.dispose();
      settingsController.dispose();
      await directory.delete(recursive: true);
    },
  );

  test('save as explicit overwrite replaces the final symlink only', () async {
    final directory = await Directory.systemTemp.createTemp(
      'busymark-save-as-symlink-',
    );
    final target = File('${directory.path}/target.md');
    final link = Link('${directory.path}/note.md');
    await target.writeAsString('# Target\n');
    await link.create(target.path);
    final harness = await _createControllerHarness();
    final settingsController = harness.settingsController;
    final controller = harness.controller;

    await controller.createMarkdownFile();
    controller.updateActiveText('# Draft\n');

    expect(
      await controller.saveActiveAs(link.path, overwriteExisting: true),
      isTrue,
    );
    expect(
      await FileSystemEntity.type(link.path, followLinks: false),
      FileSystemEntityType.file,
    );
    expect(await File(link.path).readAsString(), '# Draft\n');
    expect(await target.readAsString(), '# Target\n');

    controller.dispose();
    settingsController.dispose();
    await directory.delete(recursive: true);
  }, skip: Platform.isWindows ? 'POSIX symlink behavior only.' : false);

  test(
    'save as preserves source edits for an untitled Markdown file',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'busymark-save-as-source-',
      );
      final file = File('${directory.path}/created.md');
      final harness = await _createControllerHarness();
      final settingsController = harness.settingsController;
      final controller = harness.controller;
      const editedText = '# Created\n\nDraft text.';

      await controller.createMarkdownFile();
      controller.updateActiveText(editedText, sourceFilePath: '');

      expect(controller.state.activeText, editedText);
      expect(await controller.saveActiveAs(file.path), isTrue);
      expect(await file.readAsString(), editedText);
      expect(controller.state.activeText, editedText);
      expect(controller.state.workspace?.activeFilePath, file.path);
      expect(controller.state.isDirty, isFalse);

      controller.dispose();
      settingsController.dispose();
      await directory.delete(recursive: true);
    },
  );

  test('save as preserves edits made while writing the file', () async {
    final directory = await Directory.systemTemp.createTemp(
      'busymark-save-as-edit-during-write-',
    );
    final file = File(p.join(directory.path, 'created.md'));
    final service = _DelayedSaveAsWorkspaceService(pauseWrite: true);
    final harness = await _createControllerHarness(service: service);
    final settingsController = harness.settingsController;
    final controller = harness.controller;

    await controller.createMarkdownFile();
    controller.updateActiveText('# First draft\n');

    final save = controller.saveActiveAs(file.path);
    await service.writeStarted.future;
    controller.updateActiveText('# Newer draft\n');
    service.releaseWrite();

    expect(await save, isTrue);
    expect(await file.readAsString(), '# First draft\n');
    expect(controller.state.workspace?.activeFilePath, file.path);
    expect(controller.state.activeText, '# Newer draft\n');
    expect(controller.state.isDirty, isTrue);

    expect(await controller.saveActive(), isTrue);
    expect(await file.readAsString(), '# Newer draft\n');
    expect(controller.state.isDirty, isFalse);

    controller.dispose();
    settingsController.dispose();
    await directory.delete(recursive: true);
  });

  test('save as completes against its buffer after switching tabs', () async {
    final directory = await Directory.systemTemp.createTemp(
      'busymark-save-as-switch-tab-',
    );
    final file = File(p.join(directory.path, 'created.md'));
    final service = _DelayedSaveAsWorkspaceService(pauseWrite: true);
    final harness = await _createControllerHarness(service: service);
    final controller = harness.controller;

    await controller.createMarkdownFile();
    controller.updateActiveText('# Saved in background\n');
    final savedBufferId = controller.state.activeBuffer!.id;
    final save = controller.saveActiveAs(file.path);
    await service.writeStarted.future;

    await controller.createMarkdownFile();
    final activeUntitledId = controller.state.activeBuffer!.id;
    service.releaseWrite();

    expect(await save, isTrue);
    final savedBuffer = controller.state.documentBuffers.singleWhere(
      (buffer) => buffer.id == savedBufferId,
    );
    expect(savedBuffer.filePath, file.path);
    expect(savedBuffer.isDirty, isFalse);
    expect(controller.state.activeBuffer?.id, activeUntitledId);
    expect(controller.state.activeBuffer?.isUntitled, isTrue);
    expect(await file.readAsString(), '# Saved in background\n');

    await directory.delete(recursive: true);
  });

  test('save as preserves edits made while reopening the file', () async {
    final directory = await Directory.systemTemp.createTemp(
      'busymark-save-as-edit-during-open-',
    );
    final file = File(p.join(directory.path, 'created.md'));
    final service = _DelayedSaveAsWorkspaceService(pauseOpen: true);
    final harness = await _createControllerHarness(service: service);
    final settingsController = harness.settingsController;
    final controller = harness.controller;

    await controller.createMarkdownFile();
    controller.updateActiveText('# First draft\n');

    final save = controller.saveActiveAs(file.path);
    await service.openStarted.future;
    controller.updateActiveText('# Newer draft\n');
    service.releaseOpen();

    expect(await save, isTrue);
    expect(await file.readAsString(), '# First draft\n');
    expect(controller.state.workspace?.activeFilePath, file.path);
    expect(controller.state.activeText, '# Newer draft\n');
    expect(controller.state.isDirty, isTrue);

    expect(await controller.saveActive(), isTrue);
    expect(await file.readAsString(), '# Newer draft\n');
    expect(controller.state.isDirty, isFalse);

    controller.dispose();
    settingsController.dispose();
    await directory.delete(recursive: true);
  });

  test('switching active files reparses outline for the new file', () async {
    final harness = await _createControllerHarness();
    final settingsController = harness.settingsController;
    final controller = harness.controller;

    await controller.openPath('test/fixtures/markdown');
    final otherFile = controller.state.workspace!.files.singleWhere(
      (file) => file.relativePath == 'other.md',
    );

    await controller.openActiveFile(otherFile.absolutePath);

    expect(controller.state.workspace?.activeFilePath, otherFile.absolutePath);
    expect(
      controller.state.workspace?.markdown?.filePath,
      otherFile.absolutePath,
    );
    expect(controller.state.workspace?.markdown?.title, 'Other');
    expect(
      controller.state.workspace?.markdown?.headings.map(
        (heading) => heading.text,
      ),
      contains('Target'),
    );

    controller.dispose();
    settingsController.dispose();
  });

  test(
    'stale validation after save and tab switch does not restore previous file',
    () async {
      final service = _DelayedValidationWorkspaceService();
      final harness = await _createControllerHarness(service: service);
      final settingsController = harness.settingsController;
      final controller = harness.controller;

      await controller.openPath(service.rootPath);
      controller.updateActiveText('# Dirty A\n');

      final validation = controller.validateActive();
      await service.validationStarted.future;

      expect(await controller.saveActive(), isTrue);
      expect(await controller.openActiveFile(service.bPath), isTrue);
      controller.updateActiveText('# Dirty B\n');
      expect(await controller.saveActive(), isTrue);

      expect(controller.state.workspace?.activeFilePath, service.bPath);
      expect(controller.state.activeText, '# Dirty B\n');
      expect(service.savedTexts, ['# Dirty A\n', '# Dirty B\n']);

      service.finishValidation();
      await validation;

      expect(controller.state.workspace?.activeFilePath, service.bPath);
      expect(controller.state.activeText, '# Dirty B\n');

      controller.dispose();
      settingsController.dispose();
    },
  );

  test(
    'validation completing after save preserves the saved snapshot',
    () async {
      final service = _DelayedValidationWorkspaceService();
      final harness = await _createControllerHarness(service: service);
      final settingsController = harness.settingsController;
      final controller = harness.controller;
      await settingsController.setValidateOnEdit(false);

      await controller.openPath(service.rootPath);
      controller.updateActiveText('# Dirty A\n');
      final validation = controller.validateActive();
      await service.validationStarted.future;

      expect(await controller.saveActive(), isTrue);
      final savedSnapshot = controller.state.workspace!.activeFileSnapshot!;
      expect(savedSnapshot.contentHash, '# Dirty A\n');

      service.finishValidation();
      await validation;

      final finalSnapshot = controller.state.workspace!.activeFileSnapshot!;
      expect(finalSnapshot.contentHash, savedSnapshot.contentHash);
      expect(finalSnapshot.modifiedAt, savedSnapshot.modifiedAt);

      controller.updateActiveText('# Dirty A again\n');
      expect(await controller.saveActive(), isTrue);
      expect(
        controller.state.message?.code,
        isNot(WorkspaceMessageCode.saveBlockedFileChangedOnDisk),
      );

      controller.dispose();
      settingsController.dispose();
    },
  );

  test('Source defers preview work until a preview mode is visible', () async {
    final service = _PreviewTrackingWorkspaceService();
    final harness = await _createControllerHarness(service: service);
    final settingsController = harness.settingsController;
    final controller = harness.controller;
    await settingsController.setAutoSave(false);
    await settingsController.setValidateOnEdit(false);
    await controller.openPath('test/fixtures/markdown/basic.md');
    controller.updateActiveEditorMode(DocumentViewModePreference.source);
    service.resetCounts();

    controller.updateActiveSourceText('# Source edit one\n');
    controller.updateActiveSourceText('# Source edit two\n');
    controller.updateActiveText('# Source discrete edit\n');
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(service.reparseCount, greaterThan(0));
    expect(service.asyncPreviewBuildCount, 0);
    expect(
      controller.state.liveOutline?.headings.single.text,
      'Source discrete edit',
    );

    service.resetCounts();
    controller.updateActiveEditorMode(DocumentViewModePreference.preview);
    await _waitFor(
      () => controller.state.preview?.title == 'Source discrete edit',
    );

    expect(service.reparseCount, 1);
    expect(controller.state.activeText, '# Source discrete edit\n');

    service.resetCounts();
    controller.updateActiveEditorMode(DocumentViewModePreference.split);
    controller.updateActiveSourceText('# Live split edit\n');
    await _waitFor(() => controller.state.preview?.title == 'Live split edit');

    expect(service.reparseCount, 1);

    controller.dispose();
    settingsController.dispose();
  });

  test(
    'Source-only validation still runs when validate-on-edit is enabled',
    () async {
      final service = _PreviewTrackingWorkspaceService();
      final harness = await _createControllerHarness(service: service);
      final settingsController = harness.settingsController;
      final controller = harness.controller;
      await settingsController.setAutoSave(false);
      await settingsController.setValidateOnEdit(true);
      await controller.openPath('test/fixtures/markdown/basic.md');
      controller.updateActiveEditorMode(DocumentViewModePreference.source);
      service.resetCounts();

      controller.updateActiveSourceText('# Validate this Source edit\n');
      await _waitFor(
        () =>
            controller.state.workspace?.markdown?.source ==
            '# Validate this Source edit\n',
      );

      expect(service.reparseCount, 1);
      expect(service.synchronousPreviewBuildCount, 0);
      expect(service.asyncPreviewBuildCount, 0);

      controller.updateActiveEditorMode(DocumentViewModePreference.preview);
      await _waitFor(
        () => controller.state.preview?.title == 'Validate this Source edit',
      );

      expect(service.reparseCount, 2);
      expect(service.synchronousPreviewBuildCount, 1);
      expect(service.asyncPreviewBuildCount, 0);

      controller.dispose();
      settingsController.dispose();
    },
  );

  test(
    'stale text update from previous file cannot dirty active tab',
    () async {
      final service = _DelayedValidationWorkspaceService();
      final harness = await _createControllerHarness(service: service);
      final settingsController = harness.settingsController;
      final controller = harness.controller;

      await controller.openPath(service.rootPath);
      expect(await controller.openActiveFile(service.bPath), isTrue);

      controller.updateActiveText('# Stale A\n', sourceFilePath: service.aPath);

      expect(controller.state.workspace?.activeFilePath, service.bPath);
      expect(controller.state.activeText, '# B\n');
      expect(controller.state.isDirty, isFalse);
      expect(await controller.autoSaveActiveIfNeeded(), isTrue);
      expect(service.savedTexts, isEmpty);

      controller.dispose();
      settingsController.dispose();
    },
  );

  test('folder workspaces track open file tabs without duplicates', () async {
    final harness = await _createControllerHarness();
    final settingsController = harness.settingsController;
    final controller = harness.controller;

    await controller.openPath('test/fixtures/markdown');
    final initialPath = controller.state.workspace!.activeFilePath!;
    final otherFile = controller.state.workspace!.files.singleWhere(
      (file) => file.relativePath == 'other.md',
    );

    expect(controller.state.workspace?.openFilePaths, [initialPath]);

    await controller.openActiveFile(otherFile.absolutePath);
    await controller.openActiveFile(initialPath);

    expect(controller.state.workspace?.activeFilePath, initialPath);
    expect(controller.state.workspace?.openFilePaths, [
      initialPath,
      otherFile.absolutePath,
    ]);

    controller.dispose();
    settingsController.dispose();
  });

  test('Save All writes every dirty file-backed buffer', () async {
    final directory = await Directory.systemTemp.createTemp(
      'busymark-save-all-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final first = File(p.join(directory.path, 'a.md'))
      ..writeAsStringSync('# A\n');
    final second = File(p.join(directory.path, 'b.md'))
      ..writeAsStringSync('# B\n');
    final harness = await _createControllerHarness();
    final settingsController = harness.settingsController;
    final controller = harness.controller;

    await controller.openPath(directory.path);
    controller.updateActiveText('# Edited A\n');
    expect(await controller.openActiveFile(second.path), isTrue);
    controller.updateActiveText('# Edited B\n');

    final result = await controller.saveAll();

    expect(result.savedBufferIds, hasLength(2));
    expect(result.failedBufferIds, isEmpty);
    expect(result.conflictBufferIds, isEmpty);
    expect(controller.state.dirtyBuffers, isEmpty);
    expect(controller.state.workspace?.activeFilePath, second.path);
    expect(first.readAsStringSync(), '# Edited A\n');
    expect(second.readAsStringSync(), '# Edited B\n');

    controller.dispose();
    settingsController.dispose();
  });

  test(
    'Save All can be scoped without saving unrelated dirty buffers',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'busymark-save-selected-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final first = File(p.join(directory.path, 'a.md'))
        ..writeAsStringSync('# A\n');
      final second = File(p.join(directory.path, 'b.md'))
        ..writeAsStringSync('# B\n');
      final unrelated = File(p.join(directory.path, 'outside.md'))
        ..writeAsStringSync('# Outside\n');
      final harness = await _createControllerHarness();
      final settingsController = harness.settingsController;
      final controller = harness.controller;

      await controller.openPath(directory.path);
      controller.updateActiveText('# Edited A\n');
      expect(await controller.openActiveFile(second.path), isTrue);
      controller.updateActiveText('# Edited B\n');
      expect(await controller.openActiveFile(unrelated.path), isTrue);
      controller.updateActiveText('# Edited outside\n');
      final selectedIds = controller.state.documentBuffers
          .where(
            (buffer) =>
                buffer.filePath == first.path || buffer.filePath == second.path,
          )
          .map((buffer) => buffer.id)
          .toList();

      final result = await controller.saveAll(bufferIds: selectedIds);

      expect(result.savedBufferIds, unorderedEquals(selectedIds));
      expect(first.readAsStringSync(), '# Edited A\n');
      expect(second.readAsStringSync(), '# Edited B\n');
      expect(unrelated.readAsStringSync(), '# Outside\n');
      expect(controller.state.dirtyBuffers.map((buffer) => buffer.filePath), [
        unrelated.path,
      ]);

      controller.dispose();
      settingsController.dispose();
    },
  );

  test(
    'selected dirty buffers can be discarded without changing tabs',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'busymark-discard-selected-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final first = File(p.join(directory.path, 'a.md'))
        ..writeAsStringSync('# A\n');
      final second = File(p.join(directory.path, 'b.md'))
        ..writeAsStringSync('# B\n');
      final harness = await _createControllerHarness();
      final settingsController = harness.settingsController;
      final controller = harness.controller;

      await controller.openPath(directory.path);
      controller.updateActiveText('# Edited A\n');
      expect(await controller.openActiveFile(second.path), isTrue);
      controller.updateActiveText('# Edited B\n');
      final dirtyIds = controller.state.dirtyBuffers
          .map((buffer) => buffer.id)
          .toList();

      expect(await controller.discardDocumentBuffers(dirtyIds), isTrue);

      expect(controller.state.workspace?.activeFilePath, second.path);
      expect(controller.state.dirtyBuffers, isEmpty);
      expect(first.readAsStringSync(), '# A\n');
      expect(second.readAsStringSync(), '# B\n');
      expect(controller.state.activeText, '# B\n');

      controller.dispose();
      settingsController.dispose();
    },
  );

  test('closing active file tabs selects a neighboring tab', () async {
    final harness = await _createControllerHarness();
    final settingsController = harness.settingsController;
    final controller = harness.controller;

    await controller.openPath('test/fixtures/markdown');
    final initialPath = controller.state.workspace!.activeFilePath!;
    final otherFile = controller.state.workspace!.files.singleWhere(
      (file) => file.relativePath == 'other.md',
    );
    final linksFile = controller.state.workspace!.files.singleWhere(
      (file) => file.relativePath == 'links_images.md',
    );

    await controller.openActiveFile(otherFile.absolutePath);
    await controller.openActiveFile(linksFile.absolutePath);
    await controller.closeOpenFileTab(otherFile.absolutePath);

    expect(controller.state.workspace?.activeFilePath, linksFile.absolutePath);
    expect(controller.state.workspace?.openFilePaths, [
      initialPath,
      linksFile.absolutePath,
    ]);

    await controller.closeOpenFileTab(linksFile.absolutePath);

    expect(controller.state.workspace?.activeFilePath, initialPath);
    expect(controller.state.workspace?.openFilePaths, [initialPath]);

    await controller.closeOpenFileTab(initialPath);

    expect(controller.state.workspace?.activeFilePath, isNull);
    expect(controller.state.workspace?.activeFileSnapshot, isNull);
    expect(controller.state.workspace?.openFilePaths, isEmpty);
    expect(controller.state.activeText, isEmpty);
    expect(controller.state.preview, isNull);
    expect(controller.state.isDirty, isFalse);

    controller.dispose();
    settingsController.dispose();
  });

  test('activating sibling file tabs wraps around the open tabs', () async {
    final harness = await _createControllerHarness();
    final settingsController = harness.settingsController;
    final controller = harness.controller;

    await controller.openPath('test/fixtures/markdown');
    final initialPath = controller.state.workspace!.activeFilePath!;
    final otherFile = controller.state.workspace!.files.singleWhere(
      (file) => file.relativePath == 'other.md',
    );
    final linksFile = controller.state.workspace!.files.singleWhere(
      (file) => file.relativePath == 'links_images.md',
    );

    await controller.openActiveFile(otherFile.absolutePath);
    await controller.openActiveFile(linksFile.absolutePath);

    expect(controller.state.workspace?.activeFilePath, linksFile.absolutePath);

    await controller.activateNextOpenFileTab();

    expect(controller.state.workspace?.activeFilePath, initialPath);

    await controller.activatePreviousOpenFileTab();

    expect(controller.state.workspace?.activeFilePath, linksFile.absolutePath);

    await controller.activatePreviousOpenFileTab();

    expect(controller.state.workspace?.activeFilePath, otherFile.absolutePath);

    controller.dispose();
    settingsController.dispose();
  });

  test('closing all file tabs clears the active editor state', () async {
    final harness = await _createControllerHarness();
    final settingsController = harness.settingsController;
    final controller = harness.controller;

    await controller.openPath('test/fixtures/markdown');
    final otherFile = controller.state.workspace!.files.singleWhere(
      (file) => file.relativePath == 'other.md',
    );
    final linksFile = controller.state.workspace!.files.singleWhere(
      (file) => file.relativePath == 'links_images.md',
    );

    await controller.openActiveFile(otherFile.absolutePath);
    await controller.openActiveFile(linksFile.absolutePath);

    await controller.closeAllOpenFileTabs();

    expect(controller.state.workspace?.activeFilePath, isNull);
    expect(controller.state.workspace?.activeFileModifiedAt, isNull);
    expect(controller.state.workspace?.activeFileSnapshot, isNull);
    expect(controller.state.workspace?.openFilePaths, isEmpty);
    expect(controller.state.workspace?.markdown, isNull);
    expect(controller.state.workspace?.diagnostics, isEmpty);
    expect(controller.state.activeText, isEmpty);
    expect(controller.state.preview, isNull);
    expect(controller.state.isDirty, isFalse);

    controller.dispose();
    settingsController.dispose();
  });

  test(
    'closing all tabs aborts when a document changes during history flush',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'busymark-close-all-edit-race-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final path = p.join(directory.path, 'a.md');
      await File(path).writeAsString('# A\n');
      final historyStore = _BlockingHistoryCaptureStore();
      final harness = await _createControllerHarness(
        localHistoryStore: historyStore,
      );
      await harness.settingsController.setValidateOnEdit(false);
      final controller = harness.controller;
      await controller.openPath(directory.path);
      await _waitFor(() => historyStore.captureCount > 0);
      controller.updateActiveSourceText('# Pending checkpoint\n');
      expect(await controller.autoSaveActiveIfNeeded(), isTrue);
      expect(controller.state.activeBuffer?.isDirty, isFalse);

      historyStore.blockNextCapture = true;
      final close = controller.closeAllOpenFileTabs();
      await historyStore.captureStarted.future;
      controller.updateActiveSourceText('# Changed while Close All waits\n');
      controller.updateActiveEditorState(
        controller.state.activeBuffer!.editorState.copyWith(
          selection: const TextSelection.collapsed(offset: 9),
        ),
      );
      final live = controller.state.activeBuffer!;

      historyStore.releaseCapture.complete();
      expect(await close, isFalse);
      final surviving = controller.state.documentBuffers.singleWhere(
        (buffer) => buffer.id == live.id,
      );
      expect(surviving.text, live.text);
      expect(surviving.isDirty, isTrue);
      expect(surviving.editorState.selection, live.editorState.selection);
      expect(surviving.editorState.undoState, same(live.editorState.undoState));
      expect(controller.undoActiveBuffer(), isTrue);
      expect(controller.state.activeText, '# Pending checkpoint\n');
    },
  );

  test(
    'closing all tabs cannot clear workspace state replaced during flush',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'busymark-close-all-workspace-race-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final path = p.join(directory.path, 'a.md');
      await File(path).writeAsString('# A\n');
      final historyStore = _BlockingHistoryCaptureStore();
      final harness = await _createControllerHarness(
        localHistoryStore: historyStore,
      );
      final controller = harness.controller;
      await controller.openPath(directory.path);
      await _waitFor(() => historyStore.captureCount > 0);
      controller.updateActiveSourceText('# Pending checkpoint\n');
      expect(await controller.autoSaveActiveIfNeeded(), isTrue);
      final closingWorkspace = controller.state.workspace;

      historyStore.blockNextCapture = true;
      final close = controller.closeAllOpenFileTabs();
      await historyStore.captureStarted.future;
      await controller.createMarkdownFile();
      final replacementWorkspace = controller.state.workspace;
      final replacementBuffer = controller.state.activeBuffer!;
      expect(replacementWorkspace, isNot(same(closingWorkspace)));
      expect(replacementBuffer.isUntitled, isTrue);

      historyStore.releaseCapture.complete();
      expect(await close, isFalse);
      expect(controller.state.workspace, same(replacementWorkspace));
      expect(
        controller.state.documentBuffers.any(
          (buffer) => buffer.id == replacementBuffer.id,
        ),
        isTrue,
      );
      expect(controller.state.activeBufferId, replacementBuffer.id);
    },
  );

  test('failed open clears stale workspace state', () async {
    final harness = await _createControllerHarness();
    final settingsController = harness.settingsController;
    final controller = harness.controller;

    await controller.openPath('test/fixtures/markdown/basic.md');
    await controller.openPath('test/fixtures/markdown/does-not-exist.md');

    expect(controller.state.workspace, isNull);
    expect(controller.state.message?.code, WorkspaceMessageCode.openFailed);

    controller.dispose();
    settingsController.dispose();
  });

  test(
    'math renderer failures become source-linked runtime diagnostics',
    () async {
      final harness = await _createControllerHarness();
      final controller = harness.controller;
      await controller.openPath('test/fixtures/markdown/basic.md');
      final path = controller.state.workspace!.activeFilePath!;
      final span = SourceSpan.fromOffsets(
        filePath: path,
        source: controller.state.activeText,
        startOffset: 0,
        endOffset: 4,
      );

      controller.updateMathRenderDiagnostic(
        expressionId: 'inline-b0-i0',
        code: 'math.invalidTex',
        sourceSpan: span,
      );

      final workspace = controller.state.workspace!;
      expect(workspace.runtimeDiagnostics.single.code, 'math.invalidTex');
      expect(workspace.runtimeDiagnostics.single.sourceSpan, same(span));
      expect(
        workspace.allDiagnostics,
        contains(workspace.runtimeDiagnostics.single),
      );

      controller.updateMathRenderDiagnostic(
        expressionId: 'inline-b0-i0',
        code: null,
        sourceSpan: span,
      );
      expect(controller.state.workspace!.runtimeDiagnostics, isEmpty);

      controller.updateMathRenderDiagnostic(
        expressionId: 'inline-b0-i0',
        code: 'math.invalidTex',
        sourceSpan: span,
      );
      controller.updateActiveText('${controller.state.activeText}\n');
      expect(controller.state.workspace!.runtimeDiagnostics, isEmpty);
      await _waitFor(
        () =>
            controller.state.workspace?.markdown?.source ==
            controller.state.activeText,
      );
    },
  );

  test('validate on edit setting controls live diagnostics only', () async {
    final harness = await _createControllerHarness();
    final settingsController = harness.settingsController;
    await settingsController.setValidateOnEdit(false);
    final controller = harness.controller;

    await controller.openPath('test/fixtures/markdown/other.md');
    controller.updateActiveText('# Changed\n\nVisible preview.');
    await Future<void>.delayed(Duration.zero);

    expect(controller.state.workspace?.markdown?.title, 'Other');
    expect(controller.state.preview?.blocks.map((block) => block.text), [
      'Changed',
      'Visible preview.',
    ]);

    controller.dispose();
    settingsController.dispose();
  });

  test('auto save waits for an idle delay before writing', () async {
    final service = _AutosaveWorkspaceService();
    final harness = await _createControllerHarness(service: service);
    final settingsController = harness.settingsController;
    final controller = harness.controller;

    await controller.openPath(service.path);
    controller.updateActiveText('# Draft\n');
    await Future<void>.delayed(const Duration(milliseconds: 500));

    expect(service.savedTexts, isEmpty);
    expect(controller.state.isDirty, isTrue);

    await Future<void>.delayed(const Duration(milliseconds: 1200));

    expect(service.savedTexts, ['# Draft\n']);
    expect(controller.state.isDirty, isFalse);

    controller.dispose();
    settingsController.dispose();
  });

  test(
    'Undo and Redo reschedule autosave after the prior save settled',
    () async {
      final service = _AutosaveWorkspaceService();
      final harness = await _createControllerHarness(service: service);
      final controller = harness.controller;

      await controller.openPath(service.path);
      controller.updateActiveText('# Changed\n');
      await _waitFor(() => service.savedTexts.length == 1);
      expect(controller.state.isDirty, isFalse);

      expect(controller.undoActiveBuffer(), isTrue);
      expect(controller.state.activeText, '# Initial\n');
      await _waitFor(() => service.savedTexts.length == 2);
      expect(service.savedTexts.last, '# Initial\n');
      expect(controller.state.isDirty, isFalse);

      expect(controller.redoActiveBuffer(), isTrue);
      expect(controller.state.activeText, '# Changed\n');
      await _waitFor(() => service.savedTexts.length == 3);
      expect(service.savedTexts.last, '# Changed\n');
      expect(controller.state.isDirty, isFalse);
    },
  );

  test(
    'inactive document updates schedule autosave without changing tabs',
    () async {
      final service = _DelayedValidationWorkspaceService();
      final harness = await _createControllerHarness(service: service);
      final controller = harness.controller;

      await harness.settingsController.setValidateOnEdit(false);
      await controller.openPath(service.rootPath);
      final aId = controller.state.activeBuffer!.id;
      expect(await controller.openActiveFile(service.bPath), isTrue);
      final activeB = controller.state.activeBuffer!.id;

      expect(controller.updateDocumentText(aId, '# Inactive change\n'), isTrue);
      expect(controller.state.activeBufferId, activeB);
      await _waitFor(() => service.savedTexts.contains('# Inactive change\n'));
      expect(controller.state.activeBufferId, activeB);
      expect(
        controller.state.documentBuffers
            .singleWhere((buffer) => buffer.id == aId)
            .isDirty,
        isFalse,
      );
    },
  );

  test(
    'failed workspace refresh restores eligible autosave scheduling',
    () async {
      final service = _FailingRefreshAutosaveWorkspaceService();
      final harness = await _createControllerHarness(service: service);
      final controller = harness.controller;

      await controller.openPath(service.path);
      controller.updateActiveText('# Save after refresh failure\n');
      service.failRefresh = true;
      expect(await controller.refreshWorkspaceFromDisk(), isFalse);
      expect(controller.state.isDirty, isTrue);

      await _waitFor(() => service.savedTexts.isNotEmpty);
      expect(service.savedTexts, ['# Save after refresh failure\n']);
      expect(controller.state.isDirty, isFalse);
    },
  );

  test('disabled autosave stays disabled after a failed refresh', () async {
    final service = _FailingRefreshAutosaveWorkspaceService();
    final harness = await _createControllerHarness(service: service);
    final controller = harness.controller;

    await harness.settingsController.setAutoSave(false);
    await controller.openPath(service.path);
    controller.updateActiveText('# Remains dirty\n');
    service.failRefresh = true;
    expect(await controller.refreshWorkspaceFromDisk(), isFalse);
    await Future<void>.delayed(const Duration(milliseconds: 1700));

    expect(service.savedTexts, isEmpty);
    expect(controller.state.isDirty, isTrue);
  });

  test('auto save remains scheduled independently for inactive tabs', () async {
    final service = _DelayedValidationWorkspaceService();
    final harness = await _createControllerHarness(service: service);
    final settingsController = harness.settingsController;
    final controller = harness.controller;

    await settingsController.setValidateOnEdit(false);
    await controller.openPath(service.rootPath);
    controller.updateActiveText('# Dirty A\n');
    expect(await controller.openActiveFile(service.bPath), isTrue);
    controller.updateActiveText('# Dirty B\n');

    await _waitFor(() => service.savedTexts.length == 2);

    expect(service.savedTexts, containsAll(['# Dirty A\n', '# Dirty B\n']));
    expect(controller.state.dirtyBuffers, isEmpty);

    controller.dispose();
    settingsController.dispose();
  });

  test(
    'auto save preserves dirty state when edits happen during save',
    () async {
      final service = _AutosaveWorkspaceService(pauseFirstSave: true);
      final harness = await _createControllerHarness(service: service);
      final settingsController = harness.settingsController;
      final controller = harness.controller;

      await controller.openPath(service.path);
      controller.updateActiveText('# First\n');
      final firstSave = controller.autoSaveActiveIfNeeded();
      await service.firstSaveStarted.future;

      controller.updateActiveText('# Second\n');
      service.releaseFirstSave();

      expect(await firstSave, isTrue);
      expect(service.savedTexts, ['# First\n']);
      expect(controller.state.isDirty, isTrue);

      expect(await controller.autoSaveActiveIfNeeded(), isTrue);
      expect(service.savedTexts, ['# First\n', '# Second\n']);
      expect(controller.state.isDirty, isFalse);

      controller.dispose();
      settingsController.dispose();
    },
  );

  test('overlapping manual save writes the newer requested revision', () async {
    final service = _AutosaveWorkspaceService(pauseFirstSave: true);
    final harness = await _createControllerHarness(service: service);
    final settingsController = harness.settingsController;
    final controller = harness.controller;

    await settingsController.setAutoSave(false);
    await controller.openPath(service.path);
    controller.updateActiveText('# First\n');
    final firstSave = controller.saveActive();
    await service.firstSaveStarted.future;

    controller.updateActiveText('# Second\n');
    final secondSave = controller.saveActive();
    service.releaseFirstSave();

    expect(await firstSave, isTrue);
    expect(await secondSave, isTrue);
    expect(service.savedTexts, ['# First\n', '# Second\n']);
    expect(controller.state.isDirty, isFalse);

    controller.dispose();
    settingsController.dispose();
  });

  test(
    'manual save completes against its buffer after switching tabs',
    () async {
      final service = _AutosaveWorkspaceService(pauseFirstSave: true);
      final harness = await _createControllerHarness(service: service);
      final controller = harness.controller;

      await controller.openPath(service.path);
      controller.updateActiveText('# Saved while inactive\n');
      final savedBufferId = controller.state.activeBuffer!.id;
      final save = controller.saveActive();
      await service.firstSaveStarted.future;

      await controller.createMarkdownFile();
      expect(controller.state.activeBuffer?.id, isNot(savedBufferId));
      service.releaseFirstSave();

      expect(await save, isTrue);
      final savedBuffer = controller.state.documentBuffers.singleWhere(
        (buffer) => buffer.id == savedBufferId,
      );
      expect(savedBuffer.isDirty, isFalse);
      expect(savedBuffer.lastSavedText, '# Saved while inactive\n');
      expect(savedBuffer.diskSnapshot?.contentHash, '# Saved while inactive\n');
      expect(controller.state.activeBuffer?.isUntitled, isTrue);
    },
  );

  test('closing a buffer waits for its in-flight autosave', () async {
    final service = _AutosaveWorkspaceService(pauseFirstSave: true);
    final harness = await _createControllerHarness(service: service);
    final controller = harness.controller;

    await controller.openPath(service.path);
    controller.updateActiveText('# Pending close\n');
    final bufferId = controller.state.activeBuffer!.id;
    final autosave = controller.autoSaveActiveIfNeeded();
    await service.firstSaveStarted.future;

    var closeCompleted = false;
    final close = controller.closeDocumentBuffer(bufferId, discard: true).then((
      value,
    ) {
      closeCompleted = true;
      return value;
    });
    await Future<void>.delayed(Duration.zero);
    expect(closeCompleted, isFalse);
    expect(
      controller.state.documentBuffers.any((buffer) => buffer.id == bufferId),
      isTrue,
    );

    service.releaseFirstSave();
    expect(await autosave, isTrue);
    expect(await close, isTrue);
    expect(
      controller.state.documentBuffers.any((buffer) => buffer.id == bufferId),
      isFalse,
    );
  });

  test(
    'discard aborts when the document changes during protective history capture',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'busymark-close-history-race-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final path = p.join(directory.path, 'draft.md');
      await File(path).writeAsString('# Disk\n');
      final historyStore = _BlockingBeforeDiscardStore();
      final harness = await _createControllerHarness(
        localHistoryStore: historyStore,
      );
      await harness.settingsController.setAutoSave(false);
      final controller = harness.controller;
      await controller.openPath(path);
      controller.updateActiveText('# Approved discard state\n');
      final bufferId = controller.state.activeBuffer!.id;

      final close = controller.closeDocumentBuffer(bufferId, discard: true);
      await historyStore.captureStarted.future;
      controller.updateActiveText('# New edit while history is writing\n');
      historyStore.releaseCapture.complete();

      expect(await close, isFalse);
      final surviving = controller.state.documentBuffers.singleWhere(
        (buffer) => buffer.id == bufferId,
      );
      expect(surviving.text, '# New edit while history is writing\n');
      expect(surviving.isDirty, isTrue);
    },
  );

  test('discard waits for its buffer in-flight autosave', () async {
    final service = _AutosaveWorkspaceService(pauseFirstSave: true);
    final harness = await _createControllerHarness(service: service);
    final controller = harness.controller;

    await controller.openPath(service.path);
    controller.updateActiveText('# Pending discard\n');
    final autosave = controller.autoSaveActiveIfNeeded();
    await service.firstSaveStarted.future;

    var discardCompleted = false;
    final discard = controller.discardActiveChanges().then((value) {
      discardCompleted = true;
      return value;
    });
    await Future<void>.delayed(Duration.zero);
    expect(discardCompleted, isFalse);

    service.releaseFirstSave();
    expect(await autosave, isTrue);
    expect(await discard, isTrue);
    expect(controller.state.activeBuffer?.isDirty, isFalse);
    expect(controller.state.activeBuffer?.diskState, DocumentDiskState.present);
  });

  test(
    'manual save waits for an in-flight autosave of the same buffer',
    () async {
      final service = _AutosaveWorkspaceService(pauseFirstSave: true);
      final harness = await _createControllerHarness(service: service);
      final controller = harness.controller;

      await controller.openPath(service.path);
      controller.updateActiveText('# Autosave revision\n');
      final autosave = controller.autoSaveActiveIfNeeded();
      await service.firstSaveStarted.future;

      controller.updateActiveText('# Manual revision\n');
      final manualSave = controller.saveActive();
      await Future<void>.delayed(Duration.zero);

      expect(service.savedTexts, ['# Autosave revision\n']);
      service.releaseFirstSave();

      expect(await autosave, isTrue);
      expect(await manualSave, isTrue);
      expect(service.completedTexts, [
        '# Autosave revision\n',
        '# Manual revision\n',
      ]);
      expect(service.diskText, '# Manual revision\n');
      expect(controller.state.isDirty, isFalse);
    },
  );

  test('Save All waits for an in-flight autosave of the same buffer', () async {
    final service = _AutosaveWorkspaceService(pauseFirstSave: true);
    final harness = await _createControllerHarness(service: service);
    final controller = harness.controller;

    await controller.openPath(service.path);
    controller.updateActiveText('# Autosave revision\n');
    final autosave = controller.autoSaveActiveIfNeeded();
    await service.firstSaveStarted.future;

    controller.updateActiveText('# Save All revision\n');
    final saveAll = controller.saveAll();
    await Future<void>.delayed(Duration.zero);
    expect(service.savedTexts, ['# Autosave revision\n']);

    service.releaseFirstSave();
    expect(await autosave, isTrue);
    expect((await saveAll).succeeded, isTrue);
    expect(service.diskText, '# Save All revision\n');
    expect(controller.state.isDirty, isFalse);
  });

  test('Save As waits for an in-flight autosave of the same buffer', () async {
    final service = _AutosaveWorkspaceService(pauseFirstSave: true);
    final harness = await _createControllerHarness(service: service);
    final controller = harness.controller;

    await controller.openPath(service.path);
    controller.updateActiveText('# Autosave revision\n');
    final autosave = controller.autoSaveActiveIfNeeded();
    await service.firstSaveStarted.future;

    controller.updateActiveText('# Save As revision\n');
    final saveAs = controller.saveActiveAs('/tmp/busymark-save-as-copy.md');
    await Future<void>.delayed(Duration.zero);
    expect(service.savedTexts, ['# Autosave revision\n']);

    service.releaseFirstSave();
    expect(await autosave, isTrue);
    expect(await saveAs, isTrue);
    expect(service.diskText, '# Save As revision\n');
    expect(
      controller.state.activeBuffer?.filePath,
      '/tmp/busymark-save-as-copy.md',
    );
    expect(controller.state.isDirty, isFalse);
  });

  test('clean shutdown waits for in-flight document writes', () async {
    final service = _AutosaveWorkspaceService(pauseFirstSave: true);
    final harness = await _createControllerHarness(service: service);
    final controller = harness.controller;

    await controller.openPath(service.path);
    controller.updateActiveText('# Pending autosave\n');
    final autosave = controller.autoSaveActiveIfNeeded();
    await service.firstSaveStarted.future;

    var shutdownCompleted = false;
    final shutdown = controller.markCleanShutdown().then(
      (_) => shutdownCompleted = true,
    );
    await Future<void>.delayed(Duration.zero);
    expect(shutdownCompleted, isFalse);

    service.releaseFirstSave();
    expect(await autosave, isTrue);
    await shutdown;
    expect(shutdownCompleted, isTrue);
    expect(service.diskText, '# Pending autosave\n');
  });

  test(
    'pending history from a closed clean tab prevents a clean shutdown marker',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'busymark-closed-history-shutdown-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final aPath = p.join(directory.path, 'a.md');
      final bPath = p.join(directory.path, 'b.md');
      await File(aPath).writeAsString('# A\n');
      await File(bPath).writeAsString('# B\n');
      const failedSource = '# Saved while history is unavailable\n';
      final historyStore = _PersistentSourceFailureStore(failedSource);
      final recoveryStore = MemoryDocumentRecoveryStore();
      final harness = await _createControllerHarness(
        localHistoryStore: historyStore,
        recoveryStore: recoveryStore,
      );
      await harness.settingsController.setAutoSave(false);
      final controller = harness.controller;
      await controller.openPath(directory.path);
      if (controller.state.activeBuffer?.filePath != aPath) {
        expect(await controller.openActiveFile(aPath), isTrue);
      }
      final aId = controller.state.activeBuffer!.id;
      controller.updateActiveText(failedSource);

      expect(await controller.saveActive(), isTrue);
      expect(controller.state.activeBuffer?.isDirty, isFalse);
      expect(
        harness._container
            .read(localHistoryControllerProvider.notifier)
            .pendingSnapshotForBuffer(aId)
            ?.text,
        failedSource,
      );

      expect(await controller.openActiveFile(bPath), isTrue);
      expect(await controller.closeOpenFileTab(aPath), isTrue);
      expect(
        controller.state.documentBuffers.any((buffer) => buffer.id == aId),
        isFalse,
      );

      await controller.markCleanShutdown();
      expect(recoveryStore.value.cleanShutdown, isFalse);
      expect(
        harness._container
            .read(localHistoryControllerProvider.notifier)
            .pendingSnapshotForBuffer(aId),
        isNotNull,
      );
    },
  );

  test(
    'save refuses to overwrite external file changes without force',
    () async {
      final directory = await Directory.systemTemp.createTemp('busymark-save-');
      final file = File('${directory.path}/note.md');
      await file.writeAsString('# Original\n');
      final harness = await _createControllerHarness();
      final settingsController = harness.settingsController;
      final controller = harness.controller;

      await controller.openPath(file.path);
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await file.writeAsString('# External\n');
      controller.updateActiveText('# BusyMark\n');

      expect(await controller.saveActive(), isFalse);
      expect(await file.readAsString(), '# External\n');
      expect(
        await controller.saveActive(overwriteExternalChanges: true),
        isTrue,
      );
      expect(await file.readAsString(), '# BusyMark\n');

      controller.dispose();
      settingsController.dispose();
      await directory.delete(recursive: true);
    },
  );

  test('save treats a deleted active file as an external conflict', () async {
    final directory = await Directory.systemTemp.createTemp(
      'busymark-save-missing-',
    );
    final file = File('${directory.path}/note.md');
    await file.writeAsString('# Original\n');
    final harness = await _createControllerHarness();
    final settingsController = harness.settingsController;
    final controller = harness.controller;

    await controller.openPath(file.path);
    await file.delete();
    controller.updateActiveText('# BusyMark\n');

    expect(await controller.saveActive(), isFalse);
    expect(
      controller.state.message?.code,
      WorkspaceMessageCode.saveBlockedFileChangedOnDisk,
    );
    expect(await file.exists(), isFalse);

    controller.dispose();
    settingsController.dispose();
    await directory.delete(recursive: true);
  });

  test('save detects external rewrites with unchanged modified time', () async {
    final directory = await Directory.systemTemp.createTemp(
      'busymark-save-hash-',
    );
    final file = File('${directory.path}/note.md');
    await file.writeAsString('# Original\n');
    final harness = await _createControllerHarness();
    final settingsController = harness.settingsController;
    final controller = harness.controller;

    await controller.openPath(file.path);
    final loadedSnapshot = controller.state.workspace!.activeFileSnapshot!;
    await file.writeAsString('# External rewrite\n');
    await file.setLastModified(loadedSnapshot.modifiedAt);
    controller.updateActiveText('# BusyMark\n');

    expect(await controller.saveActive(), isFalse);
    expect(await file.readAsString(), '# External rewrite\n');
    expect(
      controller.state.message?.code,
      WorkspaceMessageCode.saveBlockedFileChangedOnDisk,
    );

    controller.dispose();
    settingsController.dispose();
    await directory.delete(recursive: true);
  });

  test('saving preserves a manually removed final newline', () async {
    final directory = await Directory.systemTemp.createTemp(
      'busymark-final-newline-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File(p.join(directory.path, 'note.md'));
    await file.writeAsString('Saved\n');
    final harness = await _createControllerHarness();

    await harness.controller.openPath(file.path);
    harness.controller.updateActiveText('Saved');

    expect(await harness.controller.saveActive(), isTrue);
    expect(await file.readAsString(), 'Saved');
    expect(
      harness.controller.state.activeBuffer?.format.hasFinalNewline,
      false,
    );
  });

  test('WYSIWYG list edits preserve a missing final newline', () async {
    final directory = await Directory.systemTemp.createTemp(
      'busymark-wysiwyg-final-newline-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File(p.join(directory.path, 'note.md'));
    await file.writeAsString('- original');
    final harness = await _createControllerHarness();

    await harness.controller.openPath(file.path);
    final document = harness.controller.state.workspace!.markdown!.busyDocument;
    harness.controller.updateActiveWysiwygText(
      '- changed\n',
      document: document,
      sourceFilePath: file.path,
    );

    expect(harness.controller.state.activeBuffer?.text, '- changed');
    expect(
      harness.controller.state.activeBuffer?.format.hasFinalNewline,
      isFalse,
    );
    expect(await harness.controller.saveActive(), isTrue);
    expect(await file.readAsString(), '- changed');
  });

  test(
    'spelling correction undo and redo restore source and rich selections',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'busymark-spelling-history-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final file = File(p.join(directory.path, 'note.md'));
      await file.writeAsString('mispelled\n');
      final harness = await _createControllerHarness();
      await harness.controller.openPath(file.path);
      final controller = harness.controller._notifier;
      final buffer = controller.state.activeBuffer!;
      controller.updateActiveEditorState(
        buffer.editorState.copyWith(
          selection: const TextSelection(baseOffset: 0, extentOffset: 9),
        ),
      );
      const beforeRich = WysiwygEditorSessionState(
        activeBlockId: 'before-block',
        anchorBlockId: 'before-block',
        anchorOffset: 0,
        extentBlockId: 'before-block',
        extentOffset: 9,
      );
      const afterRich = WysiwygEditorSessionState(
        activeBlockId: 'after-block',
        anchorBlockId: 'after-block',
        anchorOffset: 10,
        extentBlockId: 'after-block',
        extentOffset: 10,
      );
      final correctedDocument = const MarkdownParser()
          .parse(filePath: file.path, source: 'misspelled\n')
          .busyDocument;

      controller.updateActiveWysiwygText(
        'misspelled\n',
        document: correctedDocument,
        sourceFilePath: file.path,
        previousWysiwygState: beforeRich,
        wysiwygState: afterRich,
      );
      expect(
        controller.state.activeBuffer!.editorState.undoState.undo,
        hasLength(1),
      );
      expect(
        controller.state.activeBuffer!.editorState.wysiwygState,
        afterRich,
      );

      expect(controller.undoActiveBuffer(), isTrue);
      expect(controller.state.activeText, 'mispelled\n');
      expect(
        controller.state.activeBuffer!.editorState.selection,
        const TextSelection(baseOffset: 0, extentOffset: 9),
      );
      expect(
        controller.state.activeBuffer!.editorState.wysiwygState,
        beforeRich,
      );

      expect(controller.redoActiveBuffer(), isTrue);
      expect(controller.state.activeText, 'misspelled\n');
      expect(
        controller.state.activeBuffer!.editorState.wysiwygState,
        afterRich,
      );
    },
  );

  test(
    'Keep Mine retains the conflict snapshot until explicit overwrite',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'busymark-keep-mine-',
      );
      addTearDown(() => directory.delete(recursive: true));
      File(p.join(directory.path, 'a.md')).writeAsStringSync('Original\n');
      File(p.join(directory.path, 'b.md')).writeAsStringSync('Other\n');
      final monitor = WorkspaceFileMonitor(
        debounce: const Duration(milliseconds: 10),
      );
      addTearDown(monitor.dispose);
      final harness = await _createControllerHarness(fileMonitor: monitor);

      await harness.controller.openPath(directory.path);
      final path = harness.controller.state.activeBuffer!.filePath!;
      final originalSnapshot =
          harness.controller.state.activeBuffer!.diskSnapshot;
      harness.controller.updateActiveText('Mine\n');
      await File(path).writeAsString('External\n');
      await _waitFor(
        () => harness.controller.state.activeBuffer?.hasConflict == true,
      );

      harness.controller.keepBufferVersion(
        harness.controller.state.activeBuffer!.id,
      );

      expect(
        harness.controller.state.activeBuffer?.diskSnapshot,
        same(originalSnapshot),
      );
      expect(
        harness.controller.state.activeBuffer?.diskState,
        DocumentDiskState.changed,
      );
      expect(await harness.controller.saveActive(), isFalse);
      expect(await File(path).readAsString(), 'External\n');
    },
  );

  test('monitor refresh waits for an active foreground refresh', () async {
    final directory = await Directory.systemTemp.createTemp(
      'busymark-refresh-',
    );
    addTearDown(() => directory.delete(recursive: true));
    File(p.join(directory.path, 'a.md')).writeAsStringSync('# Original\n');
    final monitor = _ControlledFileMonitor();
    addTearDown(monitor.dispose);
    final service = _GatedRefreshWorkspaceService();
    final harness = await _createControllerHarness(
      service: service,
      fileMonitor: monitor,
    );
    await harness.controller.openPath(directory.path);
    service.gate = Completer<void>();
    final refresh = harness.controller.refreshWorkspaceFromDisk();
    await _waitFor(() => service.refreshStarts == 1);
    monitor.emit(directory.path);
    // Cross the controller's debounce while the foreground operation is held.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final startsWhileLoading = service.refreshStarts;
    service.gate!.complete();
    service.gate = null;
    final succeeded = await refresh;
    await _waitFor(() => !harness.controller.state.isLoading);
    expect(startsWhileLoading, 1);
    expect(succeeded, isTrue);
    expect(harness.controller.state.activeText, '# Original\n');
  });

  test(
    'workspace refresh preserves an active edit and editor history made during reparse',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'busymark-refresh-active-edit-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final path = p.join(directory.path, 'a.md');
      await File(path).writeAsString('# Disk\n');
      final service = _BlockingRefreshWorkspaceService();
      final monitor = _ControlledFileMonitor();
      final harness = await _createControllerHarness(
        service: service,
        fileMonitor: monitor,
      );
      await harness.settingsController.setAutoSave(false);
      await harness.settingsController.setValidateOnEdit(false);
      await harness.controller.openPath(directory.path);

      service.pauseNextReparse();
      final refresh = harness.controller.refreshWorkspaceFromDisk();
      await service.reparseStarted.future;
      harness.controller.updateActiveEditorState(
        harness.controller.state.activeBuffer!.editorState.copyWith(
          selection: const TextSelection.collapsed(offset: 2),
        ),
      );
      harness.controller.updateActiveSourceText('# Newer one\n');
      harness.controller.updateActiveEditorState(
        harness.controller.state.activeBuffer!.editorState.copyWith(
          selection: const TextSelection.collapsed(offset: 7),
        ),
      );
      harness.controller.updateActiveSourceText('# Newer two\n');
      expect(harness.controller.undoActiveBuffer(), isTrue);
      final duringRefresh = harness.controller.state.activeBuffer!;
      expect(duringRefresh.editorState.undoState.redo, isNotEmpty);

      service.releaseReparse();
      expect(await refresh, isTrue);
      final after = harness.controller.state.activeBuffer!;
      expect(after.text, '# Newer one\n');
      expect(after.isDirty, isTrue);
      expect(after.editorState.selection, duringRefresh.editorState.selection);
      expect(
        after.editorState.undoState.undo,
        duringRefresh.editorState.undoState.undo,
      );
      expect(
        after.editorState.undoState.redo,
        duringRefresh.editorState.undoState.redo,
      );
      expect(harness.controller.redoActiveBuffer(), isTrue);
      expect(harness.controller.state.activeText, '# Newer two\n');
    },
  );

  test(
    'tab activation reconciles edits accepted while its reparse is pending',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'busymark-activation-live-edits-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final aPath = p.join(directory.path, 'a.md');
      final bPath = p.join(directory.path, 'b.md');
      await File(aPath).writeAsString('# A\n');
      await File(bPath).writeAsString('# B\n');
      final service = _BlockingRefreshWorkspaceService();
      final harness = await _createControllerHarness(service: service);
      await harness.settingsController.setAutoSave(false);
      await harness.settingsController.setValidateOnEdit(false);
      final controller = harness.controller;
      await controller.openPath(directory.path);
      final aId = controller.state.activeBuffer!.id;
      expect(await controller.openActiveFile(bPath), isTrue);
      final bId = controller.state.activeBuffer!.id;
      expect(await controller.activateDocumentBuffer(aId), isTrue);

      service.pauseNextReparse();
      final activation = controller.activateDocumentBuffer(bId);
      await service.reparseStarted.future;
      controller.updateActiveSourceText('# A edited while B activates\n');
      expect(controller.updateDocumentText(bId, '# B newest\n'), isTrue);
      final liveA = controller.state.documentBuffers.singleWhere(
        (buffer) => buffer.id == aId,
      );
      final liveB = controller.state.documentBuffers.singleWhere(
        (buffer) => buffer.id == bId,
      );

      service.releaseReparse();
      expect(await activation, isTrue);
      expect(controller.state.activeBufferId, bId);
      expect(controller.state.activeText, '# B newest\n');
      expect(
        controller.state.documentBuffers
            .singleWhere((buffer) => buffer.id == aId)
            .text,
        liveA.text,
      );
      expect(controller.state.activeBuffer!.isDirty, isTrue);
      expect(
        controller.state.activeBuffer!.editorState.undoState.undo,
        liveB.editorState.undoState.undo,
      );
      expect(controller.undoActiveBuffer(), isTrue);
      expect(controller.state.activeText, '# B\n');
    },
  );

  test(
    'opening a new tab preserves live edits and editor history in the visible document',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'busymark-first-open-live-edits-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final aPath = p.join(directory.path, 'a.md');
      final bPath = p.join(directory.path, 'b.md');
      await File(aPath).writeAsString('# A\n');
      await File(bPath).writeAsString('# B\n');
      final service = _BlockingRefreshWorkspaceService();
      final harness = await _createControllerHarness(service: service);
      await harness.settingsController.setAutoSave(false);
      await harness.settingsController.setValidateOnEdit(false);
      final controller = harness.controller;
      await controller.openPath(directory.path);
      final aId = controller.state.activeBuffer!.id;

      service.pauseNextReparse();
      final opening = controller.openActiveFile(bPath);
      await service.reparseStarted.future;
      controller.updateActiveEditorState(
        controller.state.activeBuffer!.editorState.copyWith(
          selection: const TextSelection.collapsed(offset: 2),
        ),
      );
      controller.updateActiveSourceText('# A first edit\n');
      controller.updateActiveEditorState(
        controller.state.activeBuffer!.editorState.copyWith(
          selection: const TextSelection.collapsed(offset: 8),
        ),
      );
      controller.updateActiveSourceText('# A second edit\n');
      final liveA = controller.state.activeBuffer!;

      service.releaseReparse();
      expect(await opening, isTrue);
      final preservedA = controller.state.documentBuffers.singleWhere(
        (buffer) => buffer.id == aId,
      );
      expect(preservedA.text, liveA.text);
      expect(preservedA.isDirty, isTrue);
      expect(preservedA.editorState.selection, liveA.editorState.selection);
      expect(
        preservedA.editorState.undoState,
        same(liveA.editorState.undoState),
      );
      expect(controller.state.activeBuffer?.filePath, bPath);

      expect(await controller.activateDocumentBuffer(aId), isTrue);
      expect(controller.undoActiveBuffer(), isTrue);
      expect(controller.state.activeText, '# A first edit\n');
    },
  );

  test(
    'closing the active tab aborts if it changes during next-tab activation',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'busymark-close-activation-edit-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final aPath = p.join(directory.path, 'a.md');
      final bPath = p.join(directory.path, 'b.md');
      await File(aPath).writeAsString('# A\n');
      await File(bPath).writeAsString('# B\n');
      final service = _BlockingRefreshWorkspaceService();
      final harness = await _createControllerHarness(service: service);
      await harness.settingsController.setAutoSave(false);
      await harness.settingsController.setValidateOnEdit(false);
      final controller = harness.controller;
      await controller.openPath(directory.path);
      final aId = controller.state.activeBuffer!.id;
      expect(await controller.openActiveFile(bPath), isTrue);
      expect(await controller.activateDocumentBuffer(aId), isTrue);

      service.pauseNextReparse();
      final close = controller.closeOpenFileTab(aPath);
      await service.reparseStarted.future;
      controller.updateActiveEditorState(
        controller.state.activeBuffer!.editorState.copyWith(
          selection: const TextSelection.collapsed(offset: 2),
        ),
      );
      controller.updateActiveSourceText('# A changed during close\n');
      final liveA = controller.state.activeBuffer!;

      service.releaseReparse();
      expect(await close, isFalse);
      expect(controller.state.activeBufferId, aId);
      expect(controller.state.workspace?.openFilePaths, contains(aPath));
      final preservedA = controller.state.documentBuffers.singleWhere(
        (buffer) => buffer.id == aId,
      );
      expect(preservedA.text, liveA.text);
      expect(preservedA.isDirty, isTrue);
      expect(preservedA.editorState.selection, liveA.editorState.selection);
      expect(
        preservedA.editorState.undoState,
        same(liveA.editorState.undoState),
      );
      expect(controller.undoActiveBuffer(), isTrue);
      expect(controller.state.activeText, '# A\n');
    },
  );

  test(
    'aborted discard close preserves dirty state after an editor-only change',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'busymark-discard-activation-selection-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final aPath = p.join(directory.path, 'a.md');
      final bPath = p.join(directory.path, 'b.md');
      await File(aPath).writeAsString('# A\n');
      await File(bPath).writeAsString('# B\n');
      final service = _BlockingRefreshWorkspaceService();
      final harness = await _createControllerHarness(service: service);
      await harness.settingsController.setAutoSave(false);
      await harness.settingsController.setValidateOnEdit(false);
      await harness.settingsController.setDocumentViewMode(
        DocumentViewModePreference.source,
      );
      final controller = harness.controller;
      await controller.openPath(directory.path);
      final aId = controller.state.activeBuffer!.id;
      expect(await controller.openActiveFile(bPath), isTrue);
      expect(await controller.activateDocumentBuffer(aId), isTrue);
      final completedReparsesBeforeEdit = service.completedReparseCount;
      controller.updateActiveSourceText('# Unsaved A\n');
      await _waitFor(
        () => service.completedReparseCount > completedReparsesBeforeEdit,
      );
      final dirtyA = controller.state.activeBuffer!;
      expect(dirtyA.isDirty, isTrue);
      expect(controller.state.workspace?.activeFilePath, aPath);

      service.pauseNextReparse();
      final close = controller.closeDocumentBuffer(aId, discard: true);
      await service.reparseStarted.future;
      controller.updateActiveEditorState(
        controller.state.activeBuffer!.editorState.copyWith(
          selection: const TextSelection.collapsed(offset: 4),
        ),
      );
      final liveA = controller.state.activeBuffer!;
      expect(liveA.text, dirtyA.text);
      expect(liveA.isDirty, isTrue);
      expect(liveA, isNot(same(dirtyA)));
      expect(liveA.editorState.selection.baseOffset, 4);

      service.releaseReparse();
      expect(await close, isFalse);
      final survivingA = controller.state.documentBuffers.singleWhere(
        (buffer) => buffer.id == aId,
      );
      expect(survivingA.text, dirtyA.text);
      expect(survivingA.isDirty, isTrue);
      expect(survivingA.lastSavedText, '# A\n');
      expect(survivingA.editorState.selection, liveA.editorState.selection);
      expect(
        survivingA.editorState.undoState,
        same(liveA.editorState.undoState),
      );
      expect(controller.undoActiveBuffer(), isTrue);
      expect(controller.state.activeText, '# A\n');
    },
  );

  for (final outcome in [
    'aborted',
    'closed',
    'disabled',
    'shutdown',
    'replaced',
  ]) {
    testWidgets('discard close autosave disposition: $outcome', (tester) async {
      final service = _ClosingAutosaveWorkspaceService();
      final creating = _createControllerHarness(service: service);
      await tester.pump(Duration.zero);
      final harness = await creating;
      await harness.settingsController.setValidateOnEdit(false);
      await harness.settingsController.setDocumentViewMode(
        DocumentViewModePreference.source,
      );
      if (outcome == 'disabled') {
        await harness.settingsController.setAutoSave(false);
      }
      final controller = harness.controller;
      await controller.openPath(service.path);
      final aId = controller.state.activeBuffer!.id;
      await controller.openActiveFile(service.bPath);
      await controller.activateDocumentBuffer(aId);
      controller.updateActiveSourceText('# Unsaved A\n');
      await tester.pump(const Duration(milliseconds: 500));
      final before = controller.state.activeBuffer!;
      expect(before.isDirty, isTrue);
      expect(service.savedTexts, isEmpty);

      service.pauseActivation = true;
      final close = controller.closeDocumentBuffer(aId, discard: true);
      await tester.pump();
      expect(service.activationStarted.isCompleted, isTrue);
      if (outcome != 'closed') {
        controller.updateActiveEditorState(
          before.editorState.copyWith(
            selection: const TextSelection.collapsed(offset: 4),
          ),
        );
      }
      var shutdownCompleted = false;
      final shutdown = outcome == 'shutdown'
          ? controller._notifier.markCleanShutdown().then((_) {
              shutdownCompleted = true;
            })
          : null;
      if (outcome == 'replaced') {
        await controller.openPath('/tmp/busymark-close-replacement.md');
      }
      service.releaseActivation.complete();
      await tester.pump();
      expect(await close, outcome == 'closed');
      if (shutdown != null) {
        for (var turn = 0; turn < 20 && !shutdownCompleted; turn++) {
          await tester.pump();
        }
        expect(shutdownCompleted, isTrue);
        await shutdown;
      }

      if (outcome != 'closed' && outcome != 'replaced') {
        final surviving = controller.state.activeBuffer!;
        expect(surviving.id, aId);
        expect(surviving.text, before.text);
        expect(surviving.isDirty, isTrue);
        expect(surviving.editorState.selection.baseOffset, 4);
        expect(
          surviving.editorState.undoState,
          same(before.editorState.undoState),
        );
      }
      // No more edits: only the normal 1.5-second autosave clock may write A.
      await tester.pump(const Duration(milliseconds: 1500));
      if (outcome == 'aborted') {
        expect(service.savedTexts, ['# Unsaved A\n']);
        expect(controller.state.activeBuffer!.isDirty, isFalse);
      } else {
        expect(service.savedTexts, isEmpty);
      }
      if (outcome == 'closed') {
        expect(
          controller.state.documentBuffers.any((buffer) => buffer.id == aId),
          isFalse,
        );
      }
      if (outcome == 'replaced') {
        expect(
          controller.state.workspace!.id,
          '/tmp/busymark-close-replacement.md',
        );
        expect(controller.state.activeText, '# Initial\n');
      }
      harness._container.dispose();
    });
  }

  test(
    'tab activation does not resurrect another tab closed while waiting',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'busymark-activation-closed-tab-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final aPath = p.join(directory.path, 'a.md');
      final bPath = p.join(directory.path, 'b.md');
      final cPath = p.join(directory.path, 'c.md');
      await File(aPath).writeAsString('# A\n');
      await File(bPath).writeAsString('# B\n');
      await File(cPath).writeAsString('# C\n');
      final service = _BlockingRefreshWorkspaceService();
      final harness = await _createControllerHarness(service: service);
      final controller = harness.controller;
      await controller.openPath(directory.path);
      final aId = controller.state.activeBuffer!.id;
      expect(await controller.openActiveFile(bPath), isTrue);
      final bId = controller.state.activeBuffer!.id;
      expect(await controller.openActiveFile(cPath), isTrue);
      final cId = controller.state.activeBuffer!.id;
      expect(await controller.activateDocumentBuffer(aId), isTrue);

      service.pauseNextReparse();
      final activation = controller.activateDocumentBuffer(bId);
      await service.reparseStarted.future;
      expect(await controller.closeOpenFileTab(cPath), isTrue);
      expect(
        controller.state.documentBuffers.any((buffer) => buffer.id == cId),
        isFalse,
      );

      service.releaseReparse();
      expect(await activation, isTrue);
      expect(controller.state.activeBufferId, bId);
      expect(
        controller.state.documentBuffers.any((buffer) => buffer.id == cId),
        isFalse,
      );
      expect(controller.state.workspace?.openFilePaths, isNot(contains(cPath)));
    },
  );

  test(
    'workspace refresh preserves inactive edits and does not resurrect a closed tab',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'busymark-refresh-tabs-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final aPath = p.join(directory.path, 'a.md');
      final bPath = p.join(directory.path, 'b.md');
      await File(aPath).writeAsString('# A\n');
      await File(bPath).writeAsString('# B\n');
      final service = _BlockingRefreshWorkspaceService();
      final monitor = _ControlledFileMonitor();
      final harness = await _createControllerHarness(
        service: service,
        fileMonitor: monitor,
      );
      await harness.settingsController.setAutoSave(false);
      await harness.settingsController.setValidateOnEdit(false);
      await harness.controller.openPath(directory.path);
      expect(await harness.controller.openActiveFile(bPath), isTrue);
      final bId = harness.controller.state.activeBuffer!.id;
      expect(await harness.controller.openActiveFile(aPath), isTrue);
      final aId = harness.controller.state.activeBuffer!.id;

      service.pauseNextReparse();
      final refresh = harness.controller.refreshWorkspaceFromDisk();
      await service.reparseStarted.future;
      expect(harness.controller.updateDocumentText(bId, '# B one\n'), isTrue);
      expect(harness.controller.updateDocumentText(bId, '# B two\n'), isTrue);
      expect(await harness.controller.activateDocumentBuffer(bId), isTrue);
      expect(harness.controller.undoActiveBuffer(), isTrue);
      final editedB = harness.controller.state.activeBuffer!;
      expect(await harness.controller.activateDocumentBuffer(aId), isTrue);
      expect(await harness.controller.closeDocumentBuffer(aId), isTrue);

      service.releaseReparse();
      expect(await refresh, isTrue);
      expect(
        harness.controller.state.documentBuffers.map((buffer) => buffer.id),
        [bId],
      );
      final after = harness.controller.state.activeBuffer!;
      expect(after.text, '# B one\n');
      expect(after.isDirty, isTrue);
      expect(
        after.editorState.undoState.undo,
        editedB.editorState.undoState.undo,
      );
      expect(
        after.editorState.undoState.redo,
        editedB.editorState.undoState.redo,
      );
      expect(harness.controller.state.workspace?.activeFilePath, bPath);
      expect(harness.controller.state.workspace?.markdown?.filePath, bPath);
      expect(harness.controller.state.workspace?.markdown?.source, '# B one\n');
    },
  );

  test('workspace refresh rejects a disk load superseded by typing', () async {
    final directory = await Directory.systemTemp.createTemp(
      'busymark-refresh-load-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final path = p.join(directory.path, 'a.md');
    await File(path).writeAsString('# Initial\n');
    final service = _BlockingRefreshWorkspaceService();
    final monitor = _ControlledFileMonitor();
    final harness = await _createControllerHarness(
      service: service,
      fileMonitor: monitor,
    );
    await harness.settingsController.setAutoSave(false);
    await harness.settingsController.setValidateOnEdit(false);
    await harness.controller.openPath(directory.path);
    await File(path).writeAsString('# Disk replacement\n');

    service.pauseNextLoad(path);
    final refresh = harness.controller.refreshWorkspaceFromDisk();
    await service.loadStarted.future;
    harness.controller.updateActiveEditorState(
      harness.controller.state.activeBuffer!.editorState.copyWith(
        selection: const TextSelection.collapsed(offset: 3),
      ),
    );
    harness.controller.updateActiveSourceText('# Typed while loading\n');
    final edited = harness.controller.state.activeBuffer!;
    service.releaseLoad();

    expect(await refresh, isTrue);
    final after = harness.controller.state.activeBuffer!;
    expect(after.text, edited.text);
    expect(after.isDirty, isTrue);
    expect(after.editorState.selection, edited.editorState.selection);
    expect(after.editorState.undoState.undo, edited.editorState.undoState.undo);
  });

  test('external file moves remap the open document buffer', () async {
    final directory = await Directory.systemTemp.createTemp(
      'busymark-external-move-',
    );
    addTearDown(() => directory.delete(recursive: true));
    File(p.join(directory.path, 'a.md')).writeAsStringSync('A\n');
    File(p.join(directory.path, 'b.md')).writeAsStringSync('B\n');
    final monitor = WorkspaceFileMonitor(
      debounce: const Duration(milliseconds: 10),
    );
    addTearDown(monitor.dispose);
    final harness = await _createControllerHarness(fileMonitor: monitor);

    await harness.controller.openPath(directory.path);
    final oldPath = harness.controller.state.activeBuffer!.filePath!;
    final newPath = p.join(directory.path, 'moved.md');
    await File(oldPath).rename(newPath);
    await _waitFor(
      () => harness.controller.state.activeBuffer?.filePath == newPath,
    );

    expect(harness.controller.state.workspace?.activeFilePath, newPath);
    expect(
      harness.controller.state.workspace?.openFilePaths,
      contains(newPath),
    );
    expect(
      harness.controller.state.activeBuffer?.diskState,
      DocumentDiskState.present,
    );
  });

  test('monitors saved standalone tabs outside the workspace root', () async {
    final firstDirectory = await Directory.systemTemp.createTemp(
      'busymark-monitor-first-',
    );
    final secondDirectory = await Directory.systemTemp.createTemp(
      'busymark-monitor-second-',
    );
    addTearDown(() => firstDirectory.delete(recursive: true));
    addTearDown(() => secondDirectory.delete(recursive: true));
    final firstPath = p.join(firstDirectory.path, 'first.md');
    final secondPath = p.join(secondDirectory.path, 'second.md');
    final monitor = WorkspaceFileMonitor(
      debounce: const Duration(milliseconds: 10),
    );
    addTearDown(monitor.dispose);
    final harness = await _createControllerHarness(fileMonitor: monitor);

    await harness.controller.createMarkdownFile();
    harness.controller.updateActiveText('First\n');
    expect(await harness.controller.saveActiveAs(firstPath), isTrue);
    await harness.controller.createMarkdownFile();
    harness.controller.updateActiveText('Second\n');
    expect(await harness.controller.saveActiveAs(secondPath), isTrue);

    await File(secondPath).writeAsString('Changed externally\n');
    await _waitFor(
      () =>
          harness.controller.state.activeBuffer?.text == 'Changed externally\n',
    );

    expect(harness.controller.state.activeBuffer?.filePath, secondPath);
    expect(
      harness.controller.state.activeBuffer?.diskState,
      DocumentDiskState.present,
    );
    expect(harness.controller.state.workspace?.rootPath, firstDirectory.path);
  });

  test(
    'standalone refresh preserves saved tabs in different directories',
    () async {
      final firstDirectory = await Directory.systemTemp.createTemp(
        'busymark-refresh-first-',
      );
      final secondDirectory = await Directory.systemTemp.createTemp(
        'busymark-refresh-second-',
      );
      addTearDown(() => firstDirectory.delete(recursive: true));
      addTearDown(() => secondDirectory.delete(recursive: true));
      final firstPath = p.join(firstDirectory.path, 'first.md');
      final secondPath = p.join(secondDirectory.path, 'second.md');
      final harness = await _createControllerHarness();
      final controller = harness.controller;

      await controller.createMarkdownFile();
      controller.updateActiveText('First\n');
      expect(await controller.saveActiveAs(firstPath), isTrue);
      final firstBufferId = controller.state.activeBuffer!.id;
      await controller.createMarkdownFile();
      controller.updateActiveText('Second\n');
      expect(await controller.saveActiveAs(secondPath), isTrue);

      await File(firstPath).writeAsString('First changed externally\n');
      expect(await controller.refreshWorkspaceFromDisk(), isTrue);

      final firstBuffer = controller.state.documentBuffers.singleWhere(
        (buffer) => buffer.id == firstBufferId,
      );
      expect(firstBuffer.text, 'First changed externally\n');
      expect(firstBuffer.diskState, DocumentDiskState.present);
      expect(controller.state.activeBuffer?.filePath, secondPath);
      expect(controller.state.workspace?.rootPath, firstDirectory.path);
    },
  );

  test(
    'startup leaves a clean session closed unless reopening is enabled',
    () async {
      final missingPath = p.join(
        Directory.systemTemp.path,
        'busymark-clean-startup-session-missing.md',
      );
      final sessionStore = MemoryDocumentSessionStore()
        ..value = WorkspaceSessionSnapshot(
          workspacePath: missingPath,
          activeBufferId: 'clean-session',
          tabs: [
            DocumentSessionEntry(
              id: 'clean-session',
              filePath: missingPath,
              untitledName: null,
              editorState: const DocumentEditorState(),
            ),
          ],
        );
      final harness = await _createControllerHarness(
        sessionStore: sessionStore,
      );

      expect(
        await harness.controller.restoreStartupSession(
          reopenCleanSession: false,
        ),
        isFalse,
      );
      expect(harness.controller.state.workspace, isNull);

      expect(
        await harness.controller.restoreStartupSession(
          reopenCleanSession: true,
        ),
        isTrue,
      );
      expect(harness.controller.state.activeBuffer?.filePath, missingPath);
    },
  );

  test('startup restores an interrupted session without an opt-in', () async {
    final missingPath = p.join(
      Directory.systemTemp.path,
      'busymark-interrupted-startup-session-missing.md',
    );
    final sessionStore = MemoryDocumentSessionStore()
      ..value = WorkspaceSessionSnapshot(
        workspacePath: missingPath,
        activeBufferId: 'interrupted-session',
        tabs: [
          DocumentSessionEntry(
            id: 'interrupted-session',
            filePath: missingPath,
            untitledName: null,
            editorState: const DocumentEditorState(),
          ),
        ],
      );
    final recoveryStore = MemoryDocumentRecoveryStore()
      ..value = const RecoverySnapshot(cleanShutdown: false, entries: []);
    final harness = await _createControllerHarness(
      sessionStore: sessionStore,
      recoveryStore: recoveryStore,
    );

    expect(
      await harness.controller.restoreStartupSession(reopenCleanSession: false),
      isTrue,
    );
    expect(harness.controller.state.activeBuffer?.filePath, missingPath);
  });

  test('restored sessions retain tabs whose files are missing', () async {
    final directory = await Directory.systemTemp.createTemp(
      'busymark-missing-session-file-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final missingPath = p.join(directory.path, 'missing.md');
    final sessionStore = MemoryDocumentSessionStore()
      ..value = WorkspaceSessionSnapshot(
        workspacePath: directory.path,
        activeBufferId: 'missing',
        tabs: [
          DocumentSessionEntry(
            id: 'missing',
            filePath: missingPath,
            untitledName: null,
            editorState: const DocumentEditorState(),
          ),
        ],
      );
    final harness = await _createControllerHarness(sessionStore: sessionStore);

    expect(await harness.controller.restorePreviousSession(), isTrue);
    expect(harness.controller.state.activeBuffer?.filePath, missingPath);
    expect(harness.controller.state.activeBuffer?.text, isEmpty);
    expect(harness.controller.state.activeBuffer?.deletedOnDisk, isTrue);
  });

  test('restored standalone sessions retain a missing document', () async {
    final directory = await Directory.systemTemp.createTemp(
      'busymark-missing-standalone-session-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final missingPath = p.join(directory.path, 'missing.md');
    final sessionStore = MemoryDocumentSessionStore()
      ..value = WorkspaceSessionSnapshot(
        workspacePath: missingPath,
        activeBufferId: 'missing',
        tabs: [
          DocumentSessionEntry(
            id: 'missing',
            filePath: missingPath,
            untitledName: null,
            editorState: const DocumentEditorState(),
          ),
        ],
      );
    final harness = await _createControllerHarness(sessionStore: sessionStore);

    expect(await harness.controller.restorePreviousSession(), isTrue);
    expect(
      harness.controller.state.workspace?.kind,
      WorkspaceKind.singleMarkdown,
    );
    expect(harness.controller.state.activeBuffer?.filePath, missingPath);
    expect(harness.controller.state.activeBuffer?.text, isEmpty);
    expect(harness.controller.state.activeBuffer?.deletedOnDisk, isTrue);
  });

  test(
    'mixed untitled and saved session restores as a standalone workspace',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'busymark-mixed-standalone-session-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final savedFile = File(p.join(directory.path, 'saved.md'));
      final sessionStore = MemoryDocumentSessionStore();
      final recoveryStore = MemoryDocumentRecoveryStore();
      final initial = await _createControllerHarness(
        sessionStore: sessionStore,
        recoveryStore: recoveryStore,
      );

      await initial.controller.createMarkdownFile();
      initial.controller.updateActiveText('First untitled text');
      await initial.controller.createMarkdownFile();
      initial.controller.updateActiveText('Second saved text');
      expect(await initial.controller.saveActiveAs(savedFile.path), isTrue);
      await initial.controller.flushPersistence();

      expect(sessionStore.value?.workspacePath, savedFile.path);

      final restored = await _createControllerHarness(
        sessionStore: sessionStore,
        recoveryStore: recoveryStore,
      );
      expect(await restored.controller.restorePreviousSession(), isTrue);
      expect(
        restored.controller.state.workspace?.kind,
        WorkspaceKind.singleMarkdown,
      );
      expect(restored.controller.state.documentBuffers, hasLength(2));
      expect(
        restored.controller.state.documentBuffers.any(
          (buffer) => buffer.isUntitled && buffer.text == 'First untitled text',
        ),
        isTrue,
      );
      expect(
        restored.controller.state.documentBuffers.any(
          (buffer) =>
              buffer.filePath == savedFile.path &&
              buffer.text == 'Second saved text',
        ),
        isTrue,
      );
    },
  );

  for (final recoveredActive in [true, false]) {
    test('Writerside session restores recovered untitled CommonMark '
        '${recoveredActive ? 'active' : 'inactive'}', () async {
      final root = Directory('test/fixtures/writerside/basic_project').absolute;
      final topicPath = p.join(root.path, 'topics', 'intro.md');
      const recoveredId = 'recovered-untitled';
      const topicId = 'restored-topic';
      const recoveredText = '# Recovered heading\n\nRecovered *text*.\n';
      final recoveredBuffer = DocumentBuffer.untitled(
        id: recoveredId,
        name: 'Recovered draft',
        text: recoveredText,
      );
      final sessionStore = MemoryDocumentSessionStore()
        ..value = WorkspaceSessionSnapshot(
          workspacePath: root.path,
          activeBufferId: recoveredActive ? recoveredId : topicId,
          tabs: [
            DocumentSessionEntry(
              id: topicId,
              filePath: topicPath,
              untitledName: null,
              editorState: const DocumentEditorState(),
            ),
            const DocumentSessionEntry(
              id: recoveredId,
              filePath: null,
              untitledName: 'Recovered draft',
              editorState: DocumentEditorState(),
            ),
          ],
        );
      final recoveryStore = MemoryDocumentRecoveryStore()
        ..value = RecoverySnapshot(
          cleanShutdown: false,
          entries: [
            DocumentRecoveryEntry.fromBuffer(
              recoveredBuffer,
              workspacePath: root.path,
            ),
          ],
        );
      final harness = await _createControllerHarness(
        sessionStore: sessionStore,
        recoveryStore: recoveryStore,
      );
      final controller = harness.controller._notifier;

      expect(await controller.restorePreviousSession(), isTrue);
      expect(controller.state.workspace?.kind, WorkspaceKind.writersideModule);
      expect(controller.state.workspace?.writersideProject, isNotNull);
      if (!recoveredActive) {
        expect(controller.state.activeBuffer?.id, topicId);
        expect(await controller.activateDocumentBuffer(recoveredId), isTrue);
      }
      final state = controller.state;
      expect(state.activeBuffer?.id, recoveredId);
      expect(state.activeBuffer?.text, recoveredText);
      final resolved = resolveWorkspaceDocumentContext(
        state.workspace!,
        state.activeBuffer!,
      );
      expect(resolved.kind, DocumentKind.markdown);
      expect(resolved.markdownMode, MarkdownMode.commonMark);
      expect(state.workspace?.markdown?.mode, MarkdownMode.commonMark);
      expect(
        state.preview?.blocks.any((block) => block.text == 'Recovered heading'),
        isTrue,
      );
    });
  }

  test('clean marker cannot hide remaining recovery entries', () async {
    final recoveryStore = MemoryDocumentRecoveryStore();
    final sessionStore = MemoryDocumentSessionStore();
    final recoveredBuffer = DocumentBuffer.untitled(
      id: 'untitled:recovered',
      name: 'Recovered',
      text: 'Unsaved recovery',
    );
    recoveryStore.value = RecoverySnapshot(
      cleanShutdown: true,
      entries: [
        DocumentRecoveryEntry.fromBuffer(recoveredBuffer, workspacePath: null),
      ],
    );
    final harness = await _createControllerHarness(
      sessionStore: sessionStore,
      recoveryStore: recoveryStore,
    );

    expect(
      await harness.controller.restoreStartupSession(reopenCleanSession: false),
      isTrue,
    );
    expect(harness.controller.state.activeBuffer?.recovered, isTrue);
    expect(
      harness.controller.state.message?.code,
      WorkspaceMessageCode.recoveryRestored,
    );

    await harness.controller.markCleanShutdown();
    expect(recoveryStore.value.cleanShutdown, isFalse);
    expect(recoveryStore.value.entries, isNotEmpty);
  });

  test(
    'recovery text remains restorable when the later session save fails',
    () async {
      final recoveryStore = MemoryDocumentRecoveryStore();
      final sessionStore = _FailingDocumentSessionStore();
      final harness = await _createControllerHarness(
        sessionStore: sessionStore,
        recoveryStore: recoveryStore,
      );

      await harness.controller.createMarkdownFile();
      harness.controller.updateActiveText('Latest unsaved text');
      await harness.controller.flushPersistence();

      // Simulate an older or absent recovery file immediately before the
      // persistence attempt whose session write fails.
      await recoveryStore.writeEntries(const []);
      sessionStore.failSave = true;

      await expectLater(
        harness.controller.flushPersistence(),
        throwsA(isA<StateError>()),
      );

      expect(recoveryStore.value.entries, hasLength(1));
      expect(recoveryStore.value.entries.single.text, 'Latest unsaved text');

      final restored = await _createControllerHarness(
        sessionStore: MemoryDocumentSessionStore(),
        recoveryStore: recoveryStore,
      );
      expect(await restored.controller.restorePreviousSession(), isTrue);
      expect(restored.controller.state.activeText, 'Latest unsaved text');
      expect(restored.controller.state.activeBuffer?.recovered, isTrue);
    },
  );

  test(
    'single-document session uses no workspace path after saved tabs close',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'busymark-untitled-only-session-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final savedFile = File(p.join(directory.path, 'saved.md'));
      final sessionStore = MemoryDocumentSessionStore();
      final recoveryStore = MemoryDocumentRecoveryStore();
      final initial = await _createControllerHarness(
        sessionStore: sessionStore,
        recoveryStore: recoveryStore,
      );

      await initial.controller.createMarkdownFile();
      initial.controller.updateActiveText('Remaining untitled text');
      await initial.controller.createMarkdownFile();
      initial.controller.updateActiveText('Temporary saved text');
      expect(await initial.controller.saveActiveAs(savedFile.path), isTrue);
      final savedId = initial.controller.state.activeBuffer!.id;
      expect(await initial.controller.closeDocumentBuffer(savedId), isTrue);
      await initial.controller.flushPersistence();

      expect(
        initial.controller.state.workspace?.kind,
        WorkspaceKind.singleMarkdown,
      );
      expect(initial.controller.state.documentBuffers, hasLength(1));
      expect(initial.controller.state.activeBuffer?.isUntitled, isTrue);
      expect(sessionStore.value?.workspacePath, isNull);

      final restored = await _createControllerHarness(
        sessionStore: sessionStore,
        recoveryStore: recoveryStore,
      );
      expect(await restored.controller.restorePreviousSession(), isTrue);
      expect(
        restored.controller.state.workspace?.kind,
        WorkspaceKind.untitledMarkdown,
      );
      expect(restored.controller.state.activeText, 'Remaining untitled text');
    },
  );
}

Future<Directory> _createWritableWritersideFixture(String suffix) async {
  final root = await Directory.systemTemp.createTemp(
    'busymark-writerside-$suffix-',
  );
  final topics = Directory(p.join(root.path, 'topics'));
  await topics.create();
  await File(p.join(root.path, 'writerside.cfg')).writeAsString(
    '<ihp><topics dir="topics"/><instance src="guide.tree"/></ihp>',
  );
  await File(p.join(root.path, 'guide.tree')).writeAsString(
    '<instance-profile id="guide" name="Guide" start-page="intro.md">'
    '<toc-element topic="intro.md"/></instance-profile>',
  );
  await File(p.join(topics.path, 'intro.md')).writeAsString('# Intro\n');
  return root;
}

Future<void> _waitFor(bool Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 3));
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Timed out waiting for workspace state');
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

Future<_WorkspaceControllerHarness> _createControllerHarness({
  WorkspaceService service = const WorkspaceService(),
  WorkspaceFileMonitor? fileMonitor,
  DocumentSessionStore? sessionStore,
  DocumentRecoveryStore? recoveryStore,
  LocalHistoryStore? localHistoryStore,
}) async {
  final container = ProviderContainer(
    overrides: [
      localSettingsStoreProvider.overrideWithValue(_MemorySettingsStore()),
      workspaceServiceProvider.overrideWithValue(service),
      if (fileMonitor != null)
        workspaceFileMonitorProvider.overrideWithValue(fileMonitor),
      if (sessionStore != null)
        documentSessionStoreProvider.overrideWithValue(sessionStore),
      if (recoveryStore != null)
        documentRecoveryStoreProvider.overrideWithValue(recoveryStore),
      if (localHistoryStore != null)
        localHistoryStoreProvider.overrideWithValue(localHistoryStore),
    ],
  );
  addTearDown(container.dispose);
  container.read(appSettingsControllerProvider.notifier);
  container.read(workspaceControllerProvider.notifier);
  await Future<void>.delayed(Duration.zero);
  return _WorkspaceControllerHarness(container);
}

class _WorkspaceControllerHarness {
  _WorkspaceControllerHarness(this._container);

  final ProviderContainer _container;

  late final controller = _WorkspaceControllerDriver(_container);
  late final settingsController = _AppSettingsControllerDriver(_container);
}

class _WorkspaceControllerDriver {
  const _WorkspaceControllerDriver(this._container);

  final ProviderContainer _container;

  WorkspaceController get _notifier =>
      _container.read(workspaceControllerProvider.notifier);

  WorkspaceState get state => _container.read(workspaceControllerProvider);

  Future<void> openPath(String path) => _notifier.openPath(path);

  Future<void> createMarkdownFile() => _notifier.createMarkdownFile();

  Future<bool> createWorkspaceFile(String directoryPath, String fileName) =>
      _notifier.createWorkspaceFile(directoryPath, fileName);

  Future<bool> renameWorkspaceEntity(String path, String newName) =>
      _notifier.renameWorkspaceEntity(path, newName);

  Future<bool> moveWorkspaceEntity(String sourcePath, String targetDirectory) =>
      _notifier.moveWorkspaceEntity(sourcePath, targetDirectory);

  Future<bool> deleteWorkspaceEntity(String path) =>
      _notifier.deleteWorkspaceEntity(path);

  Future<bool> createWritersideProject(
    WritersideProjectCreateRequest request,
  ) => _notifier.createWritersideProject(request);

  Future<bool> createWritersideTopic(WritersideTopicCreateRequest request) =>
      _notifier.createWritersideTopic(request);

  Future<bool> moveWritersideTocEntry({
    required String treePath,
    required List<int> sourcePath,
    required WritersideTopicCreatePlacement placement,
    required List<int>? referencePath,
  }) => _notifier.moveWritersideTocEntry(
    treePath: treePath,
    sourcePath: sourcePath,
    placement: placement,
    referencePath: referencePath,
  );

  Future<bool> removeWritersideTocEntry({
    required String treePath,
    required List<int> nodePath,
  }) => _notifier.removeWritersideTocEntry(
    treePath: treePath,
    nodePath: nodePath,
  );

  Future<bool> renameWritersideTopicFile(
    String topicPath,
    String newFileName,
  ) => _notifier.renameWritersideTopicFile(topicPath, newFileName);

  Future<WritersideTopicRenamePlan?> prepareWritersideTopicRename(
    String topicPath,
    String newFileName, {
    required String topicModuleRoot,
  }) => _notifier.prepareWritersideTopicRename(
    topicPath,
    newFileName,
    topicModuleRoot: topicModuleRoot,
  );

  Future<bool> applyWritersideTopicRename(WritersideTopicRenamePlan plan) =>
      _notifier.applyWritersideTopicRename(plan);

  Future<bool> deleteWritersideTopicFile(String topicPath) =>
      _notifier.deleteWritersideTopicFile(topicPath);

  Future<bool> openActiveFile(String path) => _notifier.openActiveFile(path);

  Future<bool> activateNextOpenFileTab() => _notifier.activateNextOpenFileTab();

  Future<bool> activatePreviousOpenFileTab() =>
      _notifier.activatePreviousOpenFileTab();

  Future<bool> closeOpenFileTab(String path) =>
      _notifier.closeOpenFileTab(path);

  Future<bool> closeDocumentBuffer(String bufferId, {bool discard = false}) =>
      _notifier.closeDocumentBuffer(bufferId, discard: discard);

  Future<bool> closeAllOpenFileTabs() => _notifier.closeAllOpenFileTabs();

  Future<bool> activateDocumentBuffer(String bufferId) =>
      _notifier.activateDocumentBuffer(bufferId);

  void updateActiveText(String text, {String? sourceFilePath}) {
    _notifier.updateActiveText(text, sourceFilePath: sourceFilePath);
  }

  void updateActiveSourceText(String text) {
    final selection = state.activeBuffer!.editorState.selection;
    _notifier.updateActiveSourceText(
      text,
      previousSelection: selection,
      selection: selection,
    );
  }

  void updateActiveEditorState(DocumentEditorState editorState) =>
      _notifier.updateActiveEditorState(editorState);

  bool updateDocumentText(String bufferId, String text) =>
      _notifier.updateDocumentText(bufferId, text);

  bool undoActiveBuffer() => _notifier.undoActiveBuffer();

  bool redoActiveBuffer() => _notifier.redoActiveBuffer();

  void updateActiveEditorMode(DocumentViewModePreference mode) {
    _notifier.updateActiveEditorMode(mode);
  }

  void updateActiveWysiwygText(
    String text, {
    required BusyDocument document,
    String? sourceFilePath,
  }) {
    _notifier.updateActiveWysiwygText(
      text,
      document: document,
      sourceFilePath: sourceFilePath,
    );
  }

  void updateMathRenderDiagnostic({
    required String expressionId,
    required String? code,
    SourceSpan? sourceSpan,
  }) {
    _notifier.updateMathRenderDiagnostic(
      expressionId: expressionId,
      code: code,
      sourceSpan: sourceSpan,
    );
  }

  Future<bool> saveActive({bool overwriteExternalChanges = false}) =>
      _notifier.saveActive(overwriteExternalChanges: overwriteExternalChanges);

  Future<bool> saveActiveAs(String path, {bool overwriteExisting = false}) =>
      _notifier.saveActiveAs(path, overwriteExisting: overwriteExisting);

  Future<SaveAllResult> saveAll({Iterable<String>? bufferIds}) =>
      _notifier.saveAll(bufferIds: bufferIds);

  Future<bool> discardDocumentBuffers(Iterable<String> bufferIds) =>
      _notifier.discardDocumentBuffers(bufferIds);

  Future<bool> autoSaveActiveIfNeeded() => _notifier.autoSaveActiveIfNeeded();

  Future<bool> discardActiveChanges() => _notifier.discardActiveChanges();

  Future<bool> refreshWorkspaceFromDisk() =>
      _notifier.refreshWorkspaceFromDiskPreservingOpenTabs();

  void keepBufferVersion(String bufferId) =>
      _notifier.keepBufferVersion(bufferId);

  Future<ValidationOutcome> validateActive() => _notifier.validateActive();

  Future<bool> restorePreviousSession() => _notifier.restorePreviousSession();

  Future<bool> restoreStartupSession({required bool reopenCleanSession}) =>
      _notifier.restoreStartupSession(reopenCleanSession: reopenCleanSession);

  Future<void> markCleanShutdown() => _notifier.markCleanShutdown();

  Future<void> flushPersistence() => _notifier.flushPersistence();

  void dispose() {}
}

class _AppSettingsControllerDriver {
  const _AppSettingsControllerDriver(this._container);

  final ProviderContainer _container;

  AppSettingsController get _notifier =>
      _container.read(appSettingsControllerProvider.notifier);

  AppSettings get state => _container.read(appSettingsControllerProvider);

  Future<void> setDocumentViewMode(DocumentViewModePreference mode) =>
      _notifier.setDocumentViewMode(mode);

  Future<void> setValidateOnEdit(bool enabled) =>
      _notifier.setValidateOnEdit(enabled);

  Future<void> setAutoSave(bool enabled) => _notifier.setAutoSave(enabled);

  void dispose() {}
}

class _MemorySettingsStore implements LocalSettingsStore {
  Map<String, Object?> value = <String, Object?>{};

  @override
  Future<Map<String, Object?>> load() async => value;

  @override
  Future<void> save(Map<String, Object?> json) async {
    value = json;
  }
}

class _BlockingBeforeDiscardStore extends MemoryLocalHistoryStore {
  final captureStarted = Completer<void>();
  final releaseCapture = Completer<void>();

  @override
  Future<LocalHistoryCaptureResult> capture(
    LocalHistoryCaptureRequest request,
    LocalHistoryPolicy policy,
  ) async {
    if (request.reason == LocalHistoryCaptureReason.beforeDiscard) {
      captureStarted.complete();
      await releaseCapture.future;
    }
    return super.capture(request, policy);
  }
}

class _BlockingHistoryCaptureStore extends MemoryLocalHistoryStore {
  var blockNextCapture = false;
  var captureCount = 0;
  final captureStarted = Completer<void>();
  final releaseCapture = Completer<void>();

  @override
  Future<LocalHistoryCaptureResult> capture(
    LocalHistoryCaptureRequest request,
    LocalHistoryPolicy policy,
  ) async {
    captureCount++;
    if (blockNextCapture) {
      blockNextCapture = false;
      captureStarted.complete();
      await releaseCapture.future;
    }
    return super.capture(request, policy);
  }
}

class _PersistentSourceFailureStore extends MemoryLocalHistoryStore {
  _PersistentSourceFailureStore(this.failedSource);

  final String failedSource;

  @override
  Future<LocalHistoryCaptureResult> capture(
    LocalHistoryCaptureRequest request,
    LocalHistoryPolicy policy,
  ) {
    if (request.source == failedSource) {
      throw const LocalHistoryStorageException(
        'Injected persistent capture failure',
      );
    }
    return super.capture(request, policy);
  }
}

class _FailingDocumentSessionStore extends MemoryDocumentSessionStore {
  bool failSave = false;

  @override
  Future<void> save(WorkspaceSessionSnapshot snapshot) {
    if (failSave) {
      throw StateError('simulated session save failure');
    }
    return super.save(snapshot);
  }
}

class _DelayedSaveAsWorkspaceService extends WorkspaceService {
  _DelayedSaveAsWorkspaceService({
    this.pauseWrite = false,
    this.pauseOpen = false,
  });

  final bool pauseWrite;
  final bool pauseOpen;
  final writeStarted = Completer<void>();
  final openStarted = Completer<void>();
  final _releaseWrite = Completer<void>();
  final _releaseOpen = Completer<void>();

  @override
  Future<WorkspaceFileSnapshot> saveNewText(String path, String text) async {
    writeStarted.complete();
    if (pauseWrite) {
      await _releaseWrite.future;
    }
    return super.saveNewText(path, text);
  }

  @override
  Future<Workspace> openPath(String path) async {
    openStarted.complete();
    if (pauseOpen) {
      await _releaseOpen.future;
    }
    return super.openPath(path);
  }

  void releaseWrite() {
    if (!_releaseWrite.isCompleted) {
      _releaseWrite.complete();
    }
  }

  void releaseOpen() {
    if (!_releaseOpen.isCompleted) {
      _releaseOpen.complete();
    }
  }
}

class _PreviewTrackingWorkspaceService extends WorkspaceService {
  int reparseCount = 0;
  int synchronousPreviewBuildCount = 0;
  int asyncPreviewBuildCount = 0;

  void resetCounts() {
    reparseCount = 0;
    synchronousPreviewBuildCount = 0;
    asyncPreviewBuildCount = 0;
  }

  @override
  Future<Workspace> reparseDocument(
    Workspace workspace,
    DocumentBuffer buffer,
  ) {
    reparseCount++;
    return super.reparseDocument(workspace, buffer);
  }

  @override
  PreviewDocument? buildDocumentPreview(
    Workspace workspace,
    DocumentBuffer buffer,
  ) {
    synchronousPreviewBuildCount++;
    return super.buildDocumentPreview(workspace, buffer);
  }

  @override
  Future<PreviewDocument?> buildDocumentPreviewAsync(
    Workspace workspace,
    DocumentBuffer buffer,
  ) {
    asyncPreviewBuildCount++;
    return super.buildDocumentPreviewAsync(workspace, buffer);
  }
}

class _BlockingUntitledPreviewWorkspaceService extends WorkspaceService {
  final started = Completer<void>();
  final finished = Completer<void>();
  final _release = Completer<void>();
  String? _blockedBufferId;

  void blockNext(String bufferId) => _blockedBufferId = bufferId;

  void release() {
    if (!_release.isCompleted) _release.complete();
  }

  @override
  Future<PreviewDocument?> buildDocumentPreviewAsync(
    Workspace workspace,
    DocumentBuffer buffer,
  ) async {
    final preview = await super.buildDocumentPreviewAsync(workspace, buffer);
    if (_blockedBufferId != buffer.id) return preview;
    _blockedBufferId = null;
    if (!started.isCompleted) started.complete();
    await _release.future;
    if (!finished.isCompleted) finished.complete();
    return preview;
  }
}

class _RecordingDocumentSourcesWorkspaceService extends WorkspaceService {
  Map<String, String> lastSources = const {};

  @override
  Future<Workspace> withDocumentSources(
    Workspace workspace,
    Map<String, String> sources,
  ) {
    lastSources = Map.unmodifiable(sources);
    return super.withDocumentSources(workspace, sources);
  }
}

class _AutosaveWorkspaceService extends WorkspaceService {
  _AutosaveWorkspaceService({this.pauseFirstSave = false});

  final bool pauseFirstSave;
  final path = '/tmp/busymark-autosave.md';
  final savedTexts = <String>[];
  final completedTexts = <String>[];
  String? diskText;
  final firstSaveStarted = Completer<void>();
  final _releaseFirstSave = Completer<void>();

  @override
  Future<Workspace> openPath(String path) async {
    return Workspace(
      id: path,
      rootPath: path,
      kind: WorkspaceKind.singleMarkdown,
      openedAt: DateTime(2026),
      activeFilePath: path,
      activeFileSnapshot: WorkspaceFileSnapshot(
        modifiedAt: _autosaveInitialModifiedAt,
        size: 11,
        contentHash: 'initial',
      ),
      files: [
        DocumentFile(
          absolutePath: path,
          relativePath: 'autosave.md',
          kind: DocumentKind.markdown,
          size: 11,
          lastModified: _autosaveInitialModifiedAt,
        ),
      ],
      diagnostics: const [],
    );
  }

  @override
  Future<WorkspaceFileLoad> loadTextWithSnapshot(String path) async {
    return WorkspaceFileLoad(
      text: '# Initial\n',
      snapshot: WorkspaceFileSnapshot(
        modifiedAt: _autosaveInitialModifiedAt,
        size: 11,
        contentHash: 'initial',
      ),
    );
  }

  @override
  Future<bool> fileChangedSince(
    String path,
    WorkspaceFileSnapshot? knownSnapshot,
  ) async {
    return false;
  }

  @override
  Future<WorkspaceFileSnapshot> saveText(String path, String text) async {
    return _recordSave(text);
  }

  @override
  Future<WorkspaceFileSnapshot> saveNewText(String path, String text) async {
    return _recordSave(text);
  }

  Future<WorkspaceFileSnapshot> _recordSave(String text) async {
    savedTexts.add(text);
    if (pauseFirstSave && savedTexts.length == 1) {
      firstSaveStarted.complete();
      await _releaseFirstSave.future;
    } else if (!firstSaveStarted.isCompleted) {
      firstSaveStarted.complete();
    }
    completedTexts.add(text);
    diskText = text;
    return WorkspaceFileSnapshot(
      modifiedAt: DateTime(2026, 1, savedTexts.length + 1),
      size: text.length,
      contentHash: text,
    );
  }

  @override
  Future<Workspace> reparseDocument(
    Workspace workspace,
    DocumentBuffer buffer,
  ) async {
    return workspace.copyWith(diagnostics: const []);
  }

  void releaseFirstSave() {
    if (!_releaseFirstSave.isCompleted) {
      _releaseFirstSave.complete();
    }
  }
}

class _ClosingAutosaveWorkspaceService extends _AutosaveWorkspaceService {
  final bPath = '/tmp/busymark-close-autosave-b.md';
  var pauseActivation = false;
  final activationStarted = Completer<void>();
  final releaseActivation = Completer<void>();

  @override
  Future<Workspace> reparseDocument(
    Workspace workspace,
    DocumentBuffer buffer,
  ) async {
    if (pauseActivation && buffer.filePath == bPath) {
      pauseActivation = false;
      activationStarted.complete();
      await releaseActivation.future;
    }
    return super.reparseDocument(workspace, buffer);
  }
}

class _FailingRefreshAutosaveWorkspaceService
    extends _AutosaveWorkspaceService {
  var failRefresh = false;

  @override
  Future<Workspace> openPath(String path) {
    if (failRefresh) throw StateError('injected refresh failure');
    return super.openPath(path);
  }
}

class _DelayedValidationWorkspaceService extends WorkspaceService {
  final rootPath = '/tmp/busymark-delayed-validation';
  late final aPath = p.join(rootPath, 'a.md');
  late final bPath = p.join(rootPath, 'b.md');
  final savedTexts = <String>[];
  final _documents = <String, String>{};
  final _snapshots = <String, WorkspaceFileSnapshot>{};
  final validationStarted = Completer<void>();
  final _finishValidation = Completer<void>();
  var _pausedValidation = false;
  var failValidation = false;

  void _ensureDocuments() {
    _documents.putIfAbsent(aPath, () => '# A\n');
    _documents.putIfAbsent(bPath, () => '# B\n');
    _snapshots.putIfAbsent(aPath, () => _delayedSnapshot(_documents[aPath]!));
    _snapshots.putIfAbsent(bPath, () => _delayedSnapshot(_documents[bPath]!));
  }

  @override
  Future<Workspace> openPath(String path) async {
    _ensureDocuments();
    return Workspace(
      id: rootPath,
      rootPath: rootPath,
      kind: WorkspaceKind.markdownFolder,
      openedAt: DateTime(2026),
      activeFilePath: aPath,
      activeFileSnapshot: _snapshots[aPath],
      openFilePaths: [aPath],
      files: [
        DocumentFile(
          absolutePath: aPath,
          relativePath: 'a.md',
          kind: DocumentKind.markdown,
          size: 4,
          lastModified: _delayedInitialModifiedAt,
        ),
        DocumentFile(
          absolutePath: bPath,
          relativePath: 'b.md',
          kind: DocumentKind.markdown,
          size: 4,
          lastModified: _delayedInitialModifiedAt,
        ),
      ],
      diagnostics: const [],
    );
  }

  @override
  Future<WorkspaceFileLoad> loadTextWithSnapshot(String path) async {
    _ensureDocuments();
    return WorkspaceFileLoad(
      text: _documents[path]!,
      snapshot: _snapshots[path]!,
    );
  }

  @override
  Future<bool> fileChangedSince(
    String path,
    WorkspaceFileSnapshot? knownSnapshot,
  ) async {
    _ensureDocuments();
    final current = _snapshots[path];
    return knownSnapshot == null ||
        current == null ||
        current.differsFrom(knownSnapshot);
  }

  @override
  Future<WorkspaceFileSnapshot> saveText(String path, String text) async {
    savedTexts.add(text);
    final snapshot = _delayedSnapshot(text, savedTexts.length);
    _documents[path] = text;
    _snapshots[path] = snapshot;
    return snapshot;
  }

  @override
  Future<Workspace> reparseDocument(
    Workspace workspace,
    DocumentBuffer buffer,
  ) async {
    if (!_pausedValidation && buffer.text == '# Dirty A\n') {
      _pausedValidation = true;
      validationStarted.complete();
      await _finishValidation.future;
    }
    if (failValidation) throw StateError('Validation failed');
    return workspace.copyWith(diagnostics: const []);
  }

  void finishValidation() {
    if (!_finishValidation.isCompleted) {
      _finishValidation.complete();
    }
  }
}

WorkspaceFileSnapshot _delayedSnapshot(String text, [int revision = 0]) {
  return WorkspaceFileSnapshot(
    modifiedAt: DateTime(2026, 2, revision + 1),
    size: text.length,
    contentHash: text,
  );
}

final _autosaveInitialModifiedAt = DateTime(2026);
final _delayedInitialModifiedAt = DateTime(2026, 2);

class _ControlledFileMonitor extends WorkspaceFileMonitor {
  final _events = StreamController<WorkspaceFileMonitorEvent>.broadcast();
  @override
  Stream<WorkspaceFileMonitorEvent> get events => _events.stream;
  void emit(String path) => _events.add(
    WorkspaceFileMonitorEvent(
      kind: WorkspaceFileEventKind.workspaceChanged,
      path: path,
    ),
  );
  @override
  Future<void> start({
    required String rootPath,
    required Iterable<String> openFilePaths,
  }) async {}
  @override
  void updateOpenFilePaths(Iterable<String> paths) {}
  @override
  Future<void> dispose() => _events.close();
}

class _TocCreationMonitorService extends WorkspaceService {
  _TocCreationMonitorService(this.monitor);
  final _ControlledFileMonitor monitor;
  @override
  Future<Workspace> createWritersideTopic(
    Workspace workspace,
    WritersideTopicCreateRequest request, {
    String? instanceTreePath,
    String? initialSource,
    Future<void> Function()? validateBeforePublish,
  }) async {
    final result = await super.createWritersideTopic(
      workspace,
      request,
      instanceTreePath: instanceTreePath,
      validateBeforePublish: validateBeforePublish,
      initialSource: initialSource,
    );
    monitor.emit(workspace.rootPath);
    return result;
  }

  @override
  Future<WorkspaceFileLoad> loadTextWithSnapshot(String path) async {
    if (path.endsWith('/created.md')) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }
    return super.loadTextWithSnapshot(path);
  }
}

class _GatedRefreshWorkspaceService extends WorkspaceService {
  Completer<void>? gate;
  var refreshStarts = 0;
  @override
  Future<Workspace> openPath(String path) async {
    final pending = gate;
    if (pending != null) {
      refreshStarts++;
      await pending.future;
    }
    return super.openPath(path);
  }
}

class _BlockingRefreshWorkspaceService extends WorkspaceService {
  var _pauseReparse = false;
  String? _pausedLoadPath;
  var completedReparseCount = 0;
  final reparseStarted = Completer<void>();
  final loadStarted = Completer<void>();
  final _reparseRelease = Completer<void>();
  final _loadRelease = Completer<void>();

  void pauseNextReparse() => _pauseReparse = true;

  void releaseReparse() {
    if (!_reparseRelease.isCompleted) _reparseRelease.complete();
  }

  void pauseNextLoad(String path) => _pausedLoadPath = p.normalize(path);

  void releaseLoad() {
    if (!_loadRelease.isCompleted) _loadRelease.complete();
  }

  @override
  Future<WorkspaceFileLoad> loadTextWithSnapshot(String path) async {
    final loaded = await super.loadTextWithSnapshot(path);
    if (_pausedLoadPath != null &&
        p.equals(_pausedLoadPath!, p.normalize(path))) {
      _pausedLoadPath = null;
      if (!loadStarted.isCompleted) loadStarted.complete();
      await _loadRelease.future;
    }
    return loaded;
  }

  @override
  Future<Workspace> reparseDocument(
    Workspace workspace,
    DocumentBuffer buffer,
  ) async {
    final reparsed = await super.reparseDocument(workspace, buffer);
    if (_pauseReparse) {
      _pauseReparse = false;
      if (!reparseStarted.isCompleted) reparseStarted.complete();
      await _reparseRelease.future;
    }
    completedReparseCount++;
    return reparsed;
  }
}
