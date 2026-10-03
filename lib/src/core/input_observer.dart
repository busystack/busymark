import 'dart:async';
import 'dart:io';

/// Scoped observations of inputs actually consumed by a read-only model job.
/// No observer is installed for ordinary filesystem operations or mutations.
abstract class InputObserver {
  static final _key = Object();
  static InputObserver? get current => Zone.current[_key] as InputObserver?;

  T observe<T>(T Function() body) => runZoned(body, zoneValues: {_key: this});

  void path(String path, FileSystemEntityType type);
  void read(String path, List<int> bytes, {bool override = false});
  void limitedRead(String path, int bytes, {bool atLeast = false});
  void readFailed(String path);
  void directory(
    String path,
    Iterable<FileSystemEntity> entries, {
    bool complete = true,
    bool failed = false,
  });
  void incomplete();
}
