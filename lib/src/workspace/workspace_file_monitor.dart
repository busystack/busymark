import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/busymark_temporary_path.dart';

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
  var _disposed = false;
  var _generation = 0;
  Future<void>? _syncing;
  var _syncAgain = false;

  Stream<WorkspaceFileMonitorEvent> get events => _controller.stream;
  bool get isRunning => _rootPath != null;

  Future<void> start({
    required String rootPath,
    required Iterable<String> openFilePaths,
  }) async {
    if (_disposed) return;
    await stop();
    // dispose() can overtake the asynchronous stop above. A stale start must
    // not recreate filesystem subscriptions after the event stream closes.
    if (_disposed) return;
    _rootPath = p.normalize(p.absolute(rootPath));
    _openFilePaths = {
      for (final path in openFilePaths) p.normalize(p.absolute(path)),
    };
    await _syncSubscriptions();
  }

  void updateOpenFilePaths(Iterable<String> paths) {
    if (_disposed) return;
    final next = {for (final path in paths) p.normalize(p.absolute(path))};
    if (next.length == _openFilePaths.length &&
        next.containsAll(_openFilePaths)) {
      return;
    }
    _openFilePaths = next;
    unawaited(_syncSubscriptions());
  }

  Future<void> stop() async {
    _generation++;
    _rootPath = null;
    _openFilePaths = const {};
    _syncAgain = false;
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _pending.clear();
    final subscriptions = _subscriptions.values.toList(growable: false);
    _subscriptions.clear();
    await Future.wait([
      for (final subscription in subscriptions) subscription.cancel(),
    ]);
    await _syncing;
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await stop();
    await _controller.close();
  }

  Future<void> _syncSubscriptions() {
    _syncAgain = true;
    return _syncing ??= () async {
      do {
        _syncAgain = false;
        await _updateSubscriptions();
      } while (_syncAgain && !_disposed);
    }().whenComplete(() => _syncing = null);
  }

  Future<void> _updateSubscriptions() async {
    final rootPath = _rootPath, generation = _generation;
    if (rootPath == null || _disposed) return;
    bool current() => !_disposed && generation == _generation;
    final desired = <String>{};

    void watch(String path, {required bool workspaceRoot}) {
      desired.add(path);
      if (_subscriptions.containsKey(path)) return;
      try {
        // Linux inotify does not support Dart's recursive flag. Install each
        // directory watch before listing its children so structural events can
        // request another scan if the tree changes during this scan.
        _subscriptions[path] = Directory(path)
            .watch(recursive: workspaceRoot && !Platform.isLinux)
            .listen(
              (event) {
                if (current()) _receive(event, workspaceRoot: workspaceRoot);
              },
              onError: (_) {},
              onDone: () {
                if (!current()) return;
                _subscriptions.remove(path);
                unawaited(_syncSubscriptions());
              },
            );
      } on FileSystemException {
        // Directories can disappear between enumeration and subscription.
      }
    }

    final pending = [rootPath];
    while (pending.isNotEmpty && current()) {
      final path = pending.removeLast();
      watch(path, workspaceRoot: true);
      if (!Platform.isLinux) continue;
      try {
        await for (final entry in Directory(path).list(followLinks: false)) {
          if (!current()) return;
          // Never follow a workspace symlink into another filesystem tree.
          if (entry is Directory) pending.add(entry.path);
        }
      } on FileSystemException {
        // An unreadable or removed directory must not prevent other watches.
      }
    }
    if (!current()) return;
    for (final path in _openFilePaths) {
      if (!p.equals(p.dirname(path), rootPath) && !p.isWithin(rootPath, path)) {
        watch(p.dirname(path), workspaceRoot: false);
      }
    }
    for (final path in _subscriptions.keys.toList(growable: false)) {
      if (!desired.contains(path)) {
        await _subscriptions.remove(path)?.cancel();
        if (!current()) return;
      }
    }
  }

  void _receive(FileSystemEvent event, {required bool workspaceRoot}) {
    if (workspaceRoot &&
        Platform.isLinux &&
        event.isDirectory &&
        event is! FileSystemModifyEvent) {
      unawaited(_syncSubscriptions());
    }
    final classified = classifyWorkspaceFileMonitorEvent(
      event,
      openFilePaths: _openFilePaths,
      workspaceRoot: workspaceRoot,
    );
    if (classified == null) return;
    _pending[classified.path] = classified;
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
}

WorkspaceFileMonitorEvent? classifyWorkspaceFileMonitorEvent(
  FileSystemEvent event, {
  required Set<String> openFilePaths,
  required bool workspaceRoot,
}) {
  var path = p.normalize(p.absolute(event.path));
  var destination = event is FileSystemMoveEvent && event.destination != null
      ? p.normalize(p.absolute(event.destination!))
      : null;
  final sourceTemporary = _isBusyMarkTemporaryPath(path);
  final destinationTemporary =
      destination != null && _isBusyMarkTemporaryPath(destination);
  WorkspaceFileEventKind? endpointKind;
  if (sourceTemporary) {
    if (destination == null || destinationTemporary) return null;
    // The real destination was published by an internal staging rename.
    path = destination;
    destination = null;
    endpointKind = openFilePaths.contains(path)
        ? WorkspaceFileEventKind.changed
        : WorkspaceFileEventKind.workspaceChanged;
  } else if (destinationTemporary) {
    // Quarantine removes the real source. Do not expose the private name as
    // an external rename target for an editor buffer.
    destination = null;
    endpointKind = WorkspaceFileEventKind.deleted;
  }
  final openPath =
      openFilePaths.contains(path) ||
      (destination != null && openFilePaths.contains(destination));
  if (!workspaceRoot && !openPath) return null;
  final kind =
      endpointKind ??
      (event is FileSystemDeleteEvent
          ? WorkspaceFileEventKind.deleted
          : event is FileSystemMoveEvent
          ? WorkspaceFileEventKind.moved
          : openPath
          ? WorkspaceFileEventKind.changed
          : WorkspaceFileEventKind.workspaceChanged);
  return WorkspaceFileMonitorEvent(
    kind: kind,
    path: path,
    destinationPath: destination,
    isDirectory: event.isDirectory,
  );
}

bool _isBusyMarkTemporaryPath(String path) {
  final basename = p.basename(path);
  return isBusyMarkTopicStagingPath(path) ||
      basename.contains('.busymark-save-') ||
      path
          .split(p.separator)
          .any(
            (part) =>
                part.startsWith('.busymark-state-') ||
                part.startsWith('.busymark-settings-') ||
                part.startsWith('.busymark-export-'),
          );
}
