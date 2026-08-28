import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

enum WorkspaceFileEventKind { changed, deleted, moved, workspaceChanged }

class WorkspaceFileMonitorEvent {
  const WorkspaceFileMonitorEvent({
    required this.kind,
    required this.path,
    this.destinationPath,
    this.isDirectory = false,
  });

  final WorkspaceFileEventKind kind;
  final String path;
  final String? destinationPath;
  final bool isDirectory;
}

class WorkspaceFileMonitor {
  WorkspaceFileMonitor({this.debounce = const Duration(milliseconds: 180)});

  final Duration debounce;
  final _controller = StreamController<WorkspaceFileMonitorEvent>.broadcast();
  final _subscriptions = <String, StreamSubscription<FileSystemEvent>>{};
  Timer? _debounceTimer;
  final _pending = <String, WorkspaceFileMonitorEvent>{};
  Set<String> _openFilePaths = const {};
  String? _rootPath;

  Stream<WorkspaceFileMonitorEvent> get events => _controller.stream;

  Future<void> start({
    required String rootPath,
    required Iterable<String> openFilePaths,
  }) async {
    await stop();
    _rootPath = p.normalize(p.absolute(rootPath));
    _openFilePaths = {
      for (final path in openFilePaths) p.normalize(p.absolute(path)),
    };
    _syncSubscriptions();
  }

  void updateOpenFilePaths(Iterable<String> paths) {
    _openFilePaths = {for (final path in paths) p.normalize(p.absolute(path))};
    _syncSubscriptions();
  }

  Future<void> stop() async {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _pending.clear();
    final subscriptions = _subscriptions.values.toList(growable: false);
    _subscriptions.clear();
    await Future.wait([
      for (final subscription in subscriptions) subscription.cancel(),
    ]);
    _rootPath = null;
    _openFilePaths = const {};
  }

  Future<void> dispose() async {
    await stop();
    await _controller.close();
  }

  void _syncSubscriptions() {
    final rootPath = _rootPath;
    if (rootPath == null) {
      return;
    }
    final desired = <String, bool>{
      if (Directory(rootPath).existsSync()) rootPath: true,
      for (final path in _openFilePaths)
        if (!p.equals(p.dirname(path), rootPath) &&
            !p.isWithin(rootPath, path) &&
            Directory(p.dirname(path)).existsSync())
          p.dirname(path): false,
    };
    for (final path in _subscriptions.keys.toList(growable: false)) {
      if (desired.containsKey(path)) {
        continue;
      }
      final subscription = _subscriptions.remove(path);
      if (subscription != null) {
        unawaited(subscription.cancel());
      }
    }
    for (final entry in desired.entries) {
      if (_subscriptions.containsKey(entry.key)) {
        continue;
      }
      try {
        _subscriptions[entry.key] = Directory(entry.key)
            .watch(recursive: entry.value, events: FileSystemEvent.all)
            .listen(
              (event) => _receive(event, workspaceRoot: entry.value),
              onError: (_) {},
            );
      } on FileSystemException {
        // A directory can disappear between existsSync and watch(). A later
        // open-path update or monitor restart will attempt it again.
      }
    }
  }

  void _receive(FileSystemEvent event, {required bool workspaceRoot}) {
    final path = p.normalize(p.absolute(event.path));
    if (_isBusyMarkTemporaryPath(path)) {
      return;
    }
    final destination =
        event is FileSystemMoveEvent && event.destination != null
        ? p.normalize(p.absolute(event.destination!))
        : null;
    final openPath =
        _openFilePaths.contains(path) ||
        (destination != null && _openFilePaths.contains(destination));
    if (!workspaceRoot && !openPath) {
      return;
    }
    final kind = event is FileSystemDeleteEvent
        ? WorkspaceFileEventKind.deleted
        : event is FileSystemMoveEvent
        ? WorkspaceFileEventKind.moved
        : openPath
        ? WorkspaceFileEventKind.changed
        : WorkspaceFileEventKind.workspaceChanged;
    _pending[path] = WorkspaceFileMonitorEvent(
      kind: kind,
      path: path,
      destinationPath: destination,
      isDirectory: event.isDirectory,
    );
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, _flush);
  }

  void _flush() {
    final events = _pending.values.toList(growable: false);
    _pending.clear();
    for (final event in events) {
      if (!_controller.isClosed) {
        _controller.add(event);
      }
    }
  }

  bool _isBusyMarkTemporaryPath(String path) {
    final basename = p.basename(path);
    return basename.contains('.busymark-save-') ||
        path
            .split(p.separator)
            .any(
              (part) =>
                  part.startsWith('.busymark-state-') ||
                  part.startsWith('.busymark-settings-') ||
                  part.startsWith('.busymark-export-'),
            );
  }
}
