import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../core/anchored_path_guard.dart';
import '../core/busymark_exception.dart';
import '../core/busymark_temporary_path.dart';
import '../core/input_observer.dart';
import 'writerside_execution.dart';

/// Transient provenance, not a parse cache. Digests are recorded at the reads
/// that feed parsers, rather than inferred from a later filesystem snapshot.
class WritersideInputSnapshot {
  const WritersideInputSnapshot({
    required this.rootPath,
    required this.types,
    required this.reads,
    required this.directories,
    required this.consistent,
    this.limitedReads = const {},
    this.failedReads = const {},
    this.discoveryComplete = true,
    this.incompleteDirectories = const {},
    this.treeEntryLimit,
  });

  final String rootPath;
  final Map<String, FileSystemEntityType> types;
  final Map<String, ({String hash, int bytes, bool override, String? textHash})>
  reads;
  final Map<String, List<String>> directories;
  // A size rejection consumed a stat length or a bounded prefix, rather than
  // document bytes. Recheck that rejection without reading an oversized file.
  final Map<String, ({int bytes, bool atLeast})> limitedReads;
  final Set<String> failedReads;
  final bool consistent;
  final bool discoveryComplete;
  final Map<String, ({int count, bool failed})> incompleteDirectories;
  final int? treeEntryLimit;

  WritersideInputSnapshot withDiscovery(WritersideInputSnapshot next) =>
      WritersideInputSnapshot(
        rootPath: rootPath,
        types: {...types, ...next.types},
        reads: {...reads, ...next.reads},
        directories: {...directories, ...next.directories},
        limitedReads: {...limitedReads, ...next.limitedReads},
        failedReads: {...failedReads, ...next.failedReads},
        consistent: consistent && next.consistent,
        discoveryComplete: discoveryComplete && next.discoveryComplete,
        incompleteDirectories: {
          for (final entry in incompleteDirectories.entries)
            if (!next.directories.containsKey(entry.key))
              entry.key: entry.value,
          ...next.incompleteDirectories,
        },
        treeEntryLimit: treeEntryLimit ?? next.treeEntryLimit,
      );

  Future<bool> isCurrent() =>
      const WritersideExecution().run(_matchSnapshot, this);

  /// Verifies consumed readable inputs for presentation only. This cannot
  /// establish an exhaustive inventory, authorize removal, acknowledge monitor
  /// events, or turn a limited result into a complete model.
  Future<bool> observedInputsCurrent() =>
      const WritersideExecution().run(_matchObservedSnapshot, this);

  Future<bool> matchesDisk({
    bool requireDiskSources = false,
    Set<String> ignoredPaths = const {},
  }) => _matchesInputs(
    requireDiskSources: requireDiskSources,
    ignoredPaths: ignoredPaths,
  );

  Future<bool> matchesObservedInputs() =>
      _matchesInputs(allowIncompleteDiscovery: true);

  Future<bool> _matchesInputs({
    bool requireDiskSources = false,
    Set<String> ignoredPaths = const {},
    bool allowIncompleteDiscovery = false,
  }) async {
    if (!consistent || (!discoveryComplete && !allowIncompleteDiscovery)) {
      return false;
    }
    try {
      final anchor = await captureCanonicalDirectoryAnchor(rootPath);
      if (!p.equals(anchor.rootPath, rootPath)) return false;
      for (final entry in types.entries) {
        if (ignoredPaths.contains(entry.key)) continue;
        final resolution = await resolveAnchoredPath(
          anchor,
          entry.key,
          allowRoot: true,
          allowMissingAncestors: true,
        );
        if (resolution.type != entry.value) return false;
      }
      for (final entry in reads.entries) {
        if (ignoredPaths.contains(entry.key)) continue;
        if (entry.value.override && !requireDiskSources) continue;
        final resolution = await resolveAnchoredPath(
          anchor,
          entry.key,
          allowRoot: false,
        );
        if (resolution.type != FileSystemEntityType.file) return false;
        final bytes = await File(resolution.path)
            .openRead(0, entry.value.bytes + 1)
            .fold<List<int>>([], (all, chunk) => all..addAll(chunk));
        if (bytes.length != entry.value.bytes ||
            sha256.convert(bytes).toString() != entry.value.hash) {
          return false;
        }
        // A symlink replacement during the read must not validate provenance.
        await resolveAnchoredPath(anchor, entry.key, allowRoot: false);
      }
      for (final entry in limitedReads.entries) {
        if (ignoredPaths.contains(entry.key)) continue;
        final resolution = await resolveAnchoredPath(
          anchor,
          entry.key,
          allowRoot: false,
        );
        if (resolution.type != FileSystemEntityType.file) return false;
        final size = await File(resolution.path).length();
        if (entry.value.atLeast
            ? size < entry.value.bytes
            : size != entry.value.bytes) {
          return false;
        }
        await resolveAnchoredPath(anchor, entry.key, allowRoot: false);
      }
      for (final path in failedReads) {
        if (ignoredPaths.contains(path)) continue;
        final resolution = await resolveAnchoredPath(
          anchor,
          path,
          allowRoot: false,
        );
        if (resolution.type != FileSystemEntityType.file) return false;
        try {
          // A successful bounded probe means the earlier failure is no longer
          // authoritative. Never keep reusing a missing/unreadable-source model
          // after access recovers, nor read a formerly unavailable large file.
          await File(resolution.path).openRead(0, 1).drain<void>();
          return false;
        } on FileSystemException {
          await resolveAnchoredPath(anchor, path, allowRoot: false);
        }
      }
      for (final entry in directories.entries) {
        final resolution = await resolveAnchoredPath(
          anchor,
          entry.key,
          allowRoot: true,
        );
        if (resolution.type != FileSystemEntityType.directory) return false;
        final partial = incompleteDirectories[entry.key];
        if (partial?.failed == true) {
          // A failed listing is authoritative only while the bounded attempt
          // still fails. Successful access must trigger rediscovery.
          try {
            await Directory(
              resolution.path,
            ).list(followLinks: false).take(partial!.count + 1).toList();
            return false;
          } on FileSystemException {
            continue;
          }
        }
        final entries = await Directory(resolution.path)
            .list(followLinks: false)
            .take(partial?.count ?? entry.value.length + 128)
            .toList();
        if (entries.length >= entry.value.length + 128) return false;
        final ignoredNames = {
          for (final path in ignoredPaths)
            if (p.equals(p.dirname(path), entry.key)) p.basename(path),
        };
        final current = inputDirectoryEntries(entries)
            .where(
              (e) => !ignoredNames.contains(e.substring(0, e.lastIndexOf(':'))),
            )
            .toList();
        final expected = entry.value
            .where(
              (e) => !ignoredNames.contains(e.substring(0, e.lastIndexOf(':'))),
            )
            .toList();
        if (current.length != expected.length ||
            !List.generate(
              current.length,
              (i) => current[i] == expected[i],
            ).every((same) => same)) {
          return false;
        }
      }
      return true;
    } on Object {
      return false;
    }
  }

  /// Exact content incorporated for a real file; overrides cannot acknowledge
  /// a disk notification. Buffer snapshot handling is checked separately.
  String? diskHash(String path) {
    final input = reads[path];
    return input == null || input.override ? null : input.hash;
  }
}

List<String> inputDirectoryEntries(Iterable<FileSystemEntity> entries) => [
  for (final entry in entries)
    if (!isBusyMarkTopicStagingPath(entry.path) &&
        !{'.git', '.hg', '.svn'}.contains(p.basename(entry.path)))
      '${p.basename(entry.path)}:${entry is Directory
          ? 'directory'
          : entry is Link
          ? 'link'
          : 'file'}',
]..sort();

class WritersideInputRecorder extends InputObserver {
  WritersideInputRecorder(this.rootPath, {this.treeEntryLimit});
  WritersideInputRecorder.fromSnapshot(WritersideInputSnapshot snapshot)
    : rootPath = snapshot.rootPath,
      _consistent = snapshot.consistent,
      _discoveryComplete = snapshot.discoveryComplete,
      treeEntryLimit = snapshot.treeEntryLimit {
    _incompleteDirectories.addAll(snapshot.incompleteDirectories);
    _types.addAll(snapshot.types);
    _reads.addAll(snapshot.reads);
    _directories.addAll(snapshot.directories);
    _limitedReads.addAll(snapshot.limitedReads);
    _failedReads.addAll(snapshot.failedReads);
  }

  String rootPath;
  final int? treeEntryLimit;
  bool _discoveryComplete = true;
  final _incompleteDirectories = <String, ({int count, bool failed})>{};
  final _types = <String, FileSystemEntityType>{};
  final _reads =
      <String, ({String hash, int bytes, bool override, String? textHash})>{};
  final _directories = <String, List<String>>{};
  final _limitedReads = <String, ({int bytes, bool atLeast})>{};
  final _failedReads = <String>{};
  bool _consistent = true;

  @override
  void path(String path, FileSystemEntityType type) {
    if (_types.containsKey(path) && _types[path] != type) _consistent = false;
    _types[path] = type;
  }

  @override
  void read(String path, List<int> bytes, {bool override = false}) {
    String? textHash;
    try {
      textHash = sha256.convert(utf8.encode(utf8.decode(bytes))).toString();
    } on FormatException {
      textHash = null;
    }
    final value = (
      hash: sha256.convert(bytes).toString(),
      bytes: bytes.length,
      override: override,
      textHash: textHash,
    );
    if (_reads.containsKey(path) && _reads[path] != value) _consistent = false;
    _reads[path] = value;
  }

  void source(String path, String source, {bool override = false}) =>
      read(path, utf8.encode(source), override: override);

  @override
  void limitedRead(String path, int bytes, {bool atLeast = false}) {
    final value = (bytes: bytes, atLeast: atLeast);
    if (_limitedReads.containsKey(path) && _limitedReads[path] != value) {
      _consistent = false;
    }
    _limitedReads[path] = value;
  }

  @override
  void readFailed(String path) => _failedReads.add(path);

  @override
  void directory(
    String path,
    Iterable<FileSystemEntity> entries, {
    bool complete = true,
    bool failed = false,
  }) {
    final listing = entries.toList();
    final value = inputDirectoryEntries(listing);
    final before = _directories[path];
    final previous = _incompleteDirectories[path];
    if (!complete || failed) _discoveryComplete = false;
    if (before != null) {
      final retainsBefore = before.every(value.toSet().contains);
      final retainedByBefore = value.every(before.toSet().contains);
      if (previous?.failed == true) {
        // Recovery needs a complete successful listing that accounts for the
        // actual prefix consumed before the failure. An empty/limited retry
        // cannot establish that the earlier failed input was unchanged.
        if (!failed && (!complete || before.isEmpty || !retainsBefore)) {
          _consistent = false;
          return;
        }
      } else if (failed) {
        // Losing access after successfully consuming the inventory supersedes
        // that input state, even if the failing stream emitted the same names.
        _consistent = false;
      }
      if (previous == null && !failed) {
        if (complete
            ? !retainsBefore || !retainedByBefore
            : !retainedByBefore) {
          _consistent = false;
          return;
        }
        // A bounded retry cannot weaken an already complete inventory proof.
        if (!complete) return;
      } else if (!failed && complete) {
        if (!retainsBefore) {
          _consistent = false;
          return;
        }
      } else {
        // Independent scan budgets can expose nested subsets of one listing.
        // Incomparable observations prove neither a stable inventory nor safe
        // supersession. Retain the strongest compatible observed portion.
        if (!retainsBefore && !retainedByBefore) {
          _consistent = false;
          return;
        }
        if ((!failed || previous?.failed == true) &&
            retainedByBefore &&
            (!retainsBefore || listing.length <= previous!.count)) {
          return;
        }
      }
    }
    _directories[path] = value;
    if (complete && !failed) {
      _incompleteDirectories.remove(path);
    } else {
      _incompleteDirectories[path] = (count: listing.length, failed: failed);
    }
  }

  @override
  void incomplete() => _discoveryComplete = false;

  WritersideInputSnapshot get snapshot => WritersideInputSnapshot(
    rootPath: rootPath,
    types: Map.unmodifiable(_types),
    reads: Map.unmodifiable(_reads),
    directories: Map.unmodifiable({
      for (final e in _directories.entries)
        e.key: List<String>.unmodifiable(e.value),
    }),
    limitedReads: Map.unmodifiable(_limitedReads),
    failedReads: Set.unmodifiable(_failedReads),
    consistent: _consistent,
    discoveryComplete: _discoveryComplete,
    incompleteDirectories: Map.unmodifiable(_incompleteDirectories),
    treeEntryLimit: treeEntryLimit,
  );
}

Future<bool> _matchSnapshot(WritersideInputSnapshot snapshot) =>
    snapshot.matchesDisk();

class WritersideInputsChanged extends BusyMarkException {
  WritersideInputsChanged(this.rootPath)
    : super('writerside.topic-file.tree-changed', args: {'path': rootPath});
  final String rootPath;
}

Future<bool> _matchObservedSnapshot(WritersideInputSnapshot snapshot) =>
    snapshot.matchesObservedInputs();
