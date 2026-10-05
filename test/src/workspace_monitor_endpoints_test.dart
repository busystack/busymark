import 'dart:io';
import 'package:busymark/src/workspace/workspace_file_monitor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final names = [
    '/tmp/.guide.tree.busymark-topic-create-10-100-0',
    '/tmp/.guide.tree.busymark-safe-delete-10-100-0',
    '/tmp/.topic.md.busymark-safe-delete-quarantine-10-100-0',
  ];
  WorkspaceFileMonitorEvent? classify(FileSystemEvent event) =>
      classifyWorkspaceFileMonitorEvent(
        event,
        openFilePaths: {'/tmp/guide.tree'},
        workspaceRoot: true,
      );
  for (final temporary in names) {
    test('temporary-to-real move retains publication: $temporary', () {
      final event = classify(
        FileSystemMoveEvent(temporary, false, '/tmp/guide.tree'),
      )!;
      expect(event.path, '/tmp/guide.tree');
      expect(event.kind, WorkspaceFileEventKind.changed);
      expect(event.destinationPath, isNull);
    });
    test('real-to-temporary move retains deletion: $temporary', () {
      final event = classify(
        FileSystemMoveEvent('/tmp/guide.tree', false, temporary),
      )!;
      expect(event.path, '/tmp/guide.tree');
      expect(event.kind, WorkspaceFileEventKind.deleted);
      expect(event.destinationPath, isNull);
      expect(classify(FileSystemMoveEvent(temporary, false, null)), isNull);
      expect(
        classify(FileSystemMoveEvent(temporary, false, names.first)),
        isNull,
      );
      expect(classify(FileSystemCreateEvent(temporary, false)), isNull);
    });
  }
  test(
    'external moves, missing destinations and authored hidden names stay visible',
    () {
      expect(
        classify(
          FileSystemMoveEvent('/tmp/guide.tree', false, '/tmp/other.tree'),
        )!.destinationPath,
        '/tmp/other.tree',
      );
      expect(
        classify(FileSystemMoveEvent('/tmp/guide.tree', false, null))!.kind,
        WorkspaceFileEventKind.moved,
      );
      for (final path in [
        '/tmp/.hidden.md',
        '/tmp/busymark.md',
        '/tmp/.x.busymark-topic-create-custom',
      ]) {
        expect(classify(FileSystemModifyEvent(path, false, false))!.path, path);
      }
    },
  );
}
