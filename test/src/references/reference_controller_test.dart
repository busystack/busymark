import 'dart:io';
import 'dart:async';
import 'package:busymark/src/references/reference_controller.dart';
import 'package:busymark/src/references/reference_index.dart';
import 'package:busymark/src/workspace/workspace_controller.dart';
import 'package:busymark/src/workspace/workspace_model.dart';
import 'package:busymark/src/workspace/workspace_service.dart';
import 'package:busymark/src/workspace/document_buffer.dart';
import 'package:busymark/src/nextcloud_notes/application/nextcloud_connection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class IndexedWorkspace extends WorkspaceController {
  IndexedWorkspace(this.initial);
  final WorkspaceState initial;
  @override
  WorkspaceState build() => initial;
  void publish(WorkspaceState value) => state = value;
}

void main() {
  test('editor state leaves the reference corpus untouched', () async {
    final root = await Directory.systemTemp.createTemp('reference-inputs-');
    addTearDown(() => root.delete(recursive: true));
    final source = File('${root.path}/source.md');
    final target = File('${root.path}/target.md');
    await source.writeAsString('[target](target.md#old)');
    await target.writeAsString('# Old');
    final workspace = await const WorkspaceService().openPath(root.path);
    final buffer = DocumentBuffer(
      id: 'open',
      filePath: source.path,
      text: await source.readAsString(),
      lastSavedText: await source.readAsString(),
      dirty: false,
    );
    final controller = IndexedWorkspace(
      WorkspaceState(
        workspace: workspace,
        documentBuffers: [buffer],
        activeBufferId: buffer.id,
      ),
    );
    final container = ProviderContainer(
      overrides: [
        workspaceControllerProvider.overrideWith(() => controller),
        nextcloudNotesRepositoryProvider.overrideWith(
          (_) async => throw StateError('Local fixture'),
        ),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(referenceIndexProvider, (_, _) {});
    addTearDown(subscription.close);
    Future<ReferenceIndex> settle(bool Function(ReferenceIndex) ready) async {
      final deadline = DateTime.now().add(const Duration(seconds: 10));
      while (DateTime.now().isBefore(deadline)) {
        final index = container.read(referenceIndexProvider).value;
        if (index != null && ready(index)) return index;
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      throw StateError('Reference index did not settle.');
    }

    final initial = await settle((index) => index.documents.length == 2);
    controller.publish(
      container
          .read(workspaceControllerProvider)
          .copyWith(
            documentBuffers: [
              buffer.copyWith(
                editorState: buffer.editorState.copyWith(
                  selection: const TextSelection.collapsed(offset: 2),
                  scrollOffset: 42,
                  foldedRegionKeys: const {'heading'},
                ),
              ),
            ],
          ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 500));
    expect(container.read(referenceIndexProvider).value, same(initial));

    controller.publish(
      container
          .read(workspaceControllerProvider)
          .copyWith(
            documentBuffers: [buffer.edited('[target](target.md#new)')],
          ),
    );
    await settle(
      (index) => index.references.single.authored.destination.endsWith('#new'),
    );
    final monitor = container.read(workspaceFileMonitorProvider);
    await monitor.start(rootPath: root.path, openFilePaths: [source.path]);
    await target.writeAsString('# New');
    final external = await settle(
      (index) =>
          index.references.single.resolution == ReferenceResolution.resolved,
    );
    expect(external.references.single.target!.anchor, 'new');
  });

  test(
    'edits during initial indexing reuse accepted batches and reject obsolete results',
    () async {
      final root = await Directory.systemTemp.createTemp('reference-batches-');
      addTearDown(() => root.delete(recursive: true));
      for (var i = 0; i < 33; i++) {
        await File('${root.path}/$i.md').writeAsString('# Heading');
      }
      final workspace = await const WorkspaceService().openPath(root.path);
      final held = Completer<List<ParsedReferenceDocument>>();
      final started = Completer<List<ReferenceDocument>>();
      final batches = <List<ReferenceDocument>>[];
      final container = ProviderContainer(
        overrides: [
          workspaceControllerProvider.overrideWith(
            () => IndexedWorkspace(WorkspaceState(workspace: workspace)),
          ),
          nextcloudNotesRepositoryProvider.overrideWith(
            (_) async => throw StateError('Local fixture'),
          ),
          referenceBatchParserProvider.overrideWithValue((documents) async {
            batches.add(documents);
            if (batches.length == 2) {
              started.complete(documents);
              return held.future;
            }
            return documents.map(ParsedReferenceDocument.new).toList();
          }),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(referenceIndexProvider, (_, _) {});
      addTearDown(subscription.close);
      final obsolete = await started.future.timeout(
        const Duration(seconds: 10),
      );
      final edited = batches.first.first;
      final controller =
          container.read(workspaceControllerProvider.notifier)
              as IndexedWorkspace;
      controller.publish(
        WorkspaceState(
          workspace: workspace,
          activeBufferId: 'dirty',
          documentBuffers: [
            DocumentBuffer(
              id: 'dirty',
              filePath: edited.path,
              dirty: true,
              text: '# Changed\n[target](32.md)',
              lastSavedText: '# Heading',
            ),
          ],
        ),
      );
      held.complete(obsolete.map(ParsedReferenceDocument.new).toList());
      final deadline = DateTime.now().add(const Duration(seconds: 10));
      ReferenceIndex? result;
      while (DateTime.now().isBefore(deadline)) {
        final current = container.read(referenceIndexProvider).value;
        if (current?.documents[edited.identity]?.source.contains('# Changed') ==
            true) {
          result = current;
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }
      expect(result, isNotNull);
      expect(result!.documents, hasLength(33));
      expect(result.references.single.resolution, ReferenceResolution.resolved);
      expect(
        result.references.single.target!.document.path,
        '${root.path}/32.md',
      );
      expect(batches.every((b) => b.length <= 16), isTrue);
      for (final unchanged in batches.first.skip(1)) {
        expect(
          batches
              .expand((b) => b)
              .where((d) => d.identity == unchanged.identity),
          hasLength(1),
        );
      }
      expect(
        batches.expand((b) => b).where((d) => d.identity == edited.identity),
        hasLength(2),
      );
      expect(await File(edited.path!).readAsString(), '# Heading');
    },
  );
  test(
    'unopened files, dirty overlays, external edits, deletion/recovery and workspace removal invalidate derived data',
    () async {
      final root = await Directory.systemTemp.createTemp('reference-overlay-');
      addTearDown(() => root.delete(recursive: true));
      final source = File('${root.path}/source.md'),
          target = File('${root.path}/target.md');
      await source.writeAsString('[old](target.md#old)');
      await target.writeAsString('# Old');
      const service = WorkspaceService();
      var workspace = await service.openPath(root.path);
      final container = ProviderContainer(
        overrides: [
          workspaceControllerProvider.overrideWith(
            () => IndexedWorkspace(WorkspaceState(workspace: workspace)),
          ),
          nextcloudNotesRepositoryProvider.overrideWith(
            (_) async => throw StateError('Local fixture'),
          ),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(referenceIndexProvider, (_, _) {});
      addTearDown(subscription.close);
      final controller =
          container.read(workspaceControllerProvider.notifier)
              as IndexedWorkspace;
      Future<ReferenceIndex> settle(
        bool Function(ReferenceIndex) predicate,
      ) async {
        final deadline = DateTime.now().add(const Duration(seconds: 20));
        while (DateTime.now().isBefore(deadline)) {
          final value = container.read(referenceIndexProvider).value;
          if (value != null && predicate(value)) return value;
          await Future<void>.delayed(const Duration(milliseconds: 25));
        }
        throw StateError(
          'Index did not settle: ${container.read(referenceIndexProvider)}',
        );
      }

      await settle(
        (i) =>
            i.references.singleOrNull?.resolution ==
            ReferenceResolution.resolved,
      );
      controller.publish(
        WorkspaceState(
          workspace: workspace,
          activeBufferId: 'dirty',
          documentBuffers: [
            DocumentBuffer(
              id: 'dirty',
              filePath: source.path,
              text: '[new](target.md#new)',
              lastSavedText: await source.readAsString(),
              dirty: true,
            ),
          ],
        ),
      );
      await settle(
        (i) =>
            i.references.singleOrNull?.authored.destination == 'target.md#new',
      );
      expect(await source.readAsString(), '[old](target.md#old)');
      await container
          .read(workspaceFileMonitorProvider)
          .start(rootPath: root.path, openFilePaths: [source.path]);
      await target.writeAsString('# New');
      await settle(
        (i) =>
            i.references.singleOrNull?.resolution ==
                ReferenceResolution.resolved &&
            i.references.single.authored.destination.endsWith('#new'),
      );
      await target.delete();
      workspace = await service.openPath(root.path);
      controller.publish(
        container
            .read(workspaceControllerProvider)
            .copyWith(workspace: workspace),
      );
      await settle(
        (i) =>
            i.references.singleOrNull?.resolution ==
            ReferenceResolution.missing,
      );
      await target.writeAsString('# New');
      workspace = await service.openPath(root.path);
      controller.publish(
        container
            .read(workspaceControllerProvider)
            .copyWith(workspace: workspace),
      );
      await settle(
        (i) =>
            i.references.singleOrNull?.resolution ==
            ReferenceResolution.resolved,
      );
      controller.publish(const WorkspaceState());
      await settle((i) => i.documents.isEmpty);
    },
  );
}
