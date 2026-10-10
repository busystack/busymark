import 'dart:async';

import '../domain/notes_models.dart';
import 'notes_navigation.dart';
import 'notes_repository.dart';

class NotesOfflineStatus {
  const NotesOfflineStatus({
    required this.revision,
    required this.textAvailable,
    required this.requiredCount,
    required this.availableCount,
    this.missing = const [],
    this.external = const [],
    this.running = false,
    this.paused = false,
  });
  final int revision, requiredCount, availableCount;
  final bool textAvailable, running, paused;
  final List<String> missing, external;
  bool get available => textAvailable && requiredCount == availableCount;
}

/// Local retention requirements drive the existing repository resolver. This
/// owns neither credentials nor another download queue. Failed and cancelled
/// revisions wait for deliberate retry; completed SQLite bytes remain retained.
class NotesOfflineController {
  NotesOfflineController(this.repository, this.accountId) {
    _subscription = repository.changes.listen((_) => _schedule());
  }
  final NotesRepository repository;
  final String accountId;
  late final StreamSubscription<void> _subscription;
  final _changes = StreamController<void>.broadcast();
  Stream<void> get changes => _changes.stream;
  List<Map<String, dynamic>> requirements = [];
  final statuses = <String, NotesOfflineStatus>{};
  final _attempted = <String>{};
  final failures = <String, String>{};
  Timer? _debounce;
  bool _disposed = false, _running = false, _again = false;
  int _generation = 0;
  Future<void> initialize() async {
    requirements = await repository.store.offlineRequirements(accountId);
    unawaited(reconcile());
  }

  bool retained(NextcloudNote note) =>
      requirements.any((r) => _includes(r, note));
  bool individuallyRetained(String id) =>
      requirements.any((r) => r['kind'] == 'note' && r['target'] == id);
  bool categoryRetained(String category) => requirements.any(
    (r) => r['kind'] == 'category' && r['target'] == category,
  );
  bool _includes(Map<String, dynamic> r, NextcloudNote note) =>
      r['kind'] == 'pause'
      ? false
      : r['kind'] == 'note'
      ? r['target'] == note.localId
      : categoryIncludes(r['target'] as String, note.category);
  bool _active(NextcloudNote note) =>
      !requirements.any(
        (r) => r['kind'] == 'pause' && r['target'] == note.localId,
      ) &&
      requirements.any((r) => r['paused'] == 0 && _includes(r, note));
  Future<void> setRequirement(
    String kind,
    String target, {
    bool required = true,
    bool paused = false,
  }) async {
    await repository.setOfflineRequirement(
      accountId,
      kind,
      target,
      required: required,
      paused: paused,
    );
    requirements = await repository.store.offlineRequirements(accountId);
    _generation++;
    for (final note in repository.notes.where(
      (n) => n.accountId == accountId && !_active(n),
    )) {
      repository.cancelMediaDownloads(note.localId);
    }
    if (required && !paused && kind != 'pause') {
      for (final note in repository.notes.where(
        (n) =>
            n.accountId == accountId &&
            (kind == 'note'
                ? n.localId == target
                : categoryIncludes(target, n.category)),
      )) {
        _attempted.removeWhere((key) => key.startsWith('${note.localId}:'));
        failures.removeWhere((key, _) => key.startsWith('${note.localId}:'));
      }
    }
    await reconcile();
  }

  Future<void> cancelNote(String id) =>
      setRequirement('pause', id, paused: true);

  Future<void> retry([String? noteId]) async {
    for (final r in requirements.toList()) {
      if (r['kind'] == 'pause' && (noteId == null || r['target'] == noteId)) {
        await repository.setOfflineRequirement(
          accountId,
          'pause',
          r['target'] as String,
          required: false,
        );
      } else if (r['paused'] == 1 &&
          (noteId == null || r['kind'] == 'note' && r['target'] == noteId)) {
        await repository.setOfflineRequirement(
          accountId,
          r['kind'] as String,
          r['target'] as String,
        );
      }
    }
    requirements = await repository.store.offlineRequirements(accountId);
    _attempted.clear();
    failures.clear();
    await reconcile();
  }

  void _schedule() {
    if (_disposed || requirements.isEmpty) return;
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 150),
      () => unawaited(reconcile()),
    );
  }

  Future<NotesOfflineStatus> inspect(
    NextcloudNote note, {
    String? source,
  }) async {
    note = repository.noteById(note.localId) ?? note;
    final dependencies = await repository.attachmentAvailability(
      note.localId,
      source: source,
    );
    return NotesOfflineStatus(
      revision: note.revision,
      textAvailable: true,
      requiredCount: dependencies.required.length,
      availableCount: dependencies.available.length,
      missing: dependencies.required
          .where((r) => !dependencies.available.contains(r))
          .toList(),
      external: dependencies.external,
      running: _running && _active(note),
      paused: retained(note) && !_active(note),
    );
  }

  Future<void> reconcile() async {
    if (_disposed) return;
    if (_running) {
      _again = true;
      return;
    }
    _running = true;
    final generation = _generation;
    try {
      for (final note in repository.notes.where(
        (n) => n.accountId == accountId && retained(n) && !isNotesRecovery(n),
      )) {
        if (_disposed || repository.accountById(accountId) == null) return;
        var status = await inspect(note);
        statuses[note.localId] = status;
        _emit();
        if (_active(note)) {
          for (final reference in status.missing) {
            if (_disposed || generation != _generation || !_active(note)) break;
            final key = '${note.localId}:${note.revision}:$reference';
            if (!_attempted.add(key)) continue;
            try {
              final path = await repository.resolveMedia(
                accountId,
                note.localId,
                reference,
              );
              if (path == null) failures[key] = 'Attachment unavailable';
            } on Object catch (error) {
              failures[key] = error.toString();
            }
            if (repository.accountById(accountId) == null) return;
            final current = repository.noteById(note.localId);
            if (current != null) {
              status = await inspect(current);
              statuses[note.localId] = status;
              _emit();
            }
          }
        }
      }
      statuses.removeWhere((id, _) => repository.noteById(id) == null);
    } finally {
      _running = false;
      for (final entry in statuses.entries.toList()) {
        final s = entry.value;
        statuses[entry.key] = NotesOfflineStatus(
          revision: s.revision,
          textAvailable: s.textAvailable,
          requiredCount: s.requiredCount,
          availableCount: s.availableCount,
          missing: s.missing,
          external: s.external,
          paused: s.paused,
        );
      }
      _emit();
      if (_again && !_disposed) {
        _again = false;
        _schedule();
      }
    }
  }

  void _emit() {
    if (!_disposed) _changes.add(null);
  }

  Future<void> dispose() async {
    _disposed = true;
    _generation++;
    _debounce?.cancel();
    for (final note in repository.notes.where(
      (n) => n.accountId == accountId && retained(n),
    )) {
      repository.cancelMediaDownloads(note.localId);
    }
    await _subscription.cancel();
    await _changes.close();
  }
}
