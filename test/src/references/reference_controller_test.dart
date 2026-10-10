import 'dart:io';
import 'package:busymark/src/references/reference_controller.dart';
import 'package:busymark/src/references/reference_index.dart';
import 'package:busymark/src/workspace/workspace_controller.dart';
import 'package:busymark/src/workspace/workspace_model.dart';
import 'package:busymark/src/workspace/workspace_service.dart';
import 'package:busymark/src/workspace/document_buffer.dart';
import 'package:busymark/src/nextcloud_notes/application/nextcloud_connection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class IndexedWorkspace extends WorkspaceController {
  IndexedWorkspace(this.initial);
  final WorkspaceState initial;
  @override
  WorkspaceState build() => initial;
  void publish(WorkspaceState value) => state = value;
}

void main() {
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
      await target.writeAsString('# New');
      controller.publish(
        container.read(workspaceControllerProvider).copyWith(),
      );
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
