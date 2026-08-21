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
  StreamSubscription<FileSystemEvent>? _subscription;
  Timer? _debounceTimer;
  final _pending = <String, WorkspaceFileMonitorEvent>{};
  Set<String> _openFilePaths = const {};

  Stream<WorkspaceFileMonitorEvent> get events => _controller.stream;

  Future<void> start({
    required String rootPath,
    required Iterable<String> openFilePaths,
  }) async {
    await stop();
    final normalizedRoot = p.normalize(p.absolute(rootPath));
    _openFilePaths = {
      for (final path in openFilePaths) p.normalize(p.absolute(path)),
    };
    final directory = Directory(normalizedRoot);
    if (!directory.existsSync()) {
      return;
    }
    _subscription = directory
        .watch(recursive: true, events: FileSystemEvent.all)
        .listen(_receive, onError: (_) {});
  }

  void updateOpenFilePaths(Iterable<String> paths) {
    _openFilePaths = {for (final path in paths) p.normalize(p.absolute(path))};
  }

  Future<void> stop() async {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _pending.clear();
    await _subscription?.cancel();
    _subscription = null;
  }

  Future<void> dispose() async {
    await stop();
    await _controller.close();
  }

  void _receive(FileSystemEvent event) {
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
