import 'dart:async';
import 'dart:io';

import 'package:busymark/src/workspace/workspace_file_monitor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  late WorkspaceFileMonitor monitor;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('busymark-nested-monitor-');
    monitor = WorkspaceFileMonitor(debounce: const Duration(milliseconds: 20));
  });
  tearDown(() async {
    await monitor.dispose();
    await root.delete(recursive: true);
  });

  Future<WorkspaceFileMonitorEvent> eventFor(String path) => monitor.events
      .firstWhere(
        (event) => event.path == path || event.destinationPath == path,
      )
      .timeout(const Duration(seconds: 5));

  test(
    'nested closed files report edits, deletion and atomic replacement',
    () async {
      final directory = await Directory(
        p.join(root.path, 'topics', 'nested'),
      ).create(recursive: true);
      final file = await File(
        p.join(directory.path, 'document.md'),
      ).writeAsString('a');
      await monitor.start(rootPath: root.path, openFilePaths: const []);

      var next = eventFor(file.path);
      await file.writeAsString('modified');
      expect((await next).kind, WorkspaceFileEventKind.workspaceChanged);

      next = eventFor(file.path);
      await file.delete();
      expect((await next).kind, WorkspaceFileEventKind.deleted);

      next = eventFor(file.path);
      await File(
        p.join(directory.path, '.replacement'),
      ).writeAsString('replacement');
      await File(p.join(directory.path, '.replacement')).rename(file.path);
      expect(
        (await next).path,
        anyOf(file.path, p.join(directory.path, '.replacement')),
      );
    },
  );

  test(
    'new and renamed directories acquire watches and removed paths retire',
    () async {
      await monitor.start(rootPath: root.path, openFilePaths: const []);
      final directory = Directory(p.join(root.path, 'new'));
      var next = eventFor(directory.path);
      await directory.create();
      expect((await next).isDirectory, isTrue);
      final file = File(p.join(directory.path, 'new.md'));
      next = eventFor(file.path);
      await file.writeAsString('created');
      await next;

      final renamedPath = p.join(root.path, 'renamed');
      next = eventFor(directory.path);
      await directory.rename(renamedPath);
      await next;
      final renamedFile = File(p.join(renamedPath, 'new.md'));
      next = eventFor(renamedFile.path);
      await renamedFile.writeAsString('modified after rename');
      await next;

      next = eventFor(renamedPath);
      await Directory(renamedPath).delete(recursive: true);
      await next;
      next = eventFor(directory.path);
      await directory.create();
      await next;
      next = eventFor(file.path);
      await file.writeAsString('recreated');
      await next;
    },
  );

  test(
    'switching workspaces retires old watches and does not follow symlinks',
    () async {
      final other = await Directory.systemTemp.createTemp(
        'busymark-other-monitor-',
      );
      addTearDown(() => other.delete(recursive: true));
      final outside = await File(
        p.join(other.path, 'outside.md'),
      ).writeAsString('a');
      await Link(p.join(root.path, 'outside')).create(other.path);
      final oldFile = await File(
        p.join(root.path, 'old.md'),
      ).writeAsString('a');
      final events = <WorkspaceFileMonitorEvent>[];
      final subscription = monitor.events.listen(events.add);
      addTearDown(subscription.cancel);
      await monitor.start(rootPath: root.path, openFilePaths: const []);
      await outside.writeAsString('not a workspace file');
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(events, isEmpty);

      await monitor.start(rootPath: other.path, openFilePaths: const []);
      final next = eventFor(outside.path);
      await oldFile.writeAsString('old workspace');
      await outside.writeAsString('new workspace');
      await next;
      expect(events.any((event) => event.path == oldFile.path), isFalse);
    },
  );
}
