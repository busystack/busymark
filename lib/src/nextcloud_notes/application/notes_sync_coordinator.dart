import 'dart:async';

import '../domain/notes_models.dart';
import 'notes_repository.dart';

enum NotesSyncTrigger {
  opening,
  localChange,
  manual,
  focus,
  poll,
  retry,
  recovery,
}

abstract interface class NotesScheduledTask {
  void cancel();
}

class _TimerTask implements NotesScheduledTask {
  _TimerTask(Duration delay, void Function() callback)
    : timer = Timer(delay, callback);
  final Timer timer;
  @override
  void cancel() => timer.cancel();
}

typedef NotesSchedule = NotesScheduledTask Function(Duration, void Function());

/// Scheduling only. The repository remains the sole synchronization engine.
class NotesSyncCoordinator {
  NotesSyncCoordinator(
    this.repository, {
    DateTime Function()? clock,
    NotesSchedule? schedule,
    this.onError,
  }) : clock = clock ?? DateTime.now,
       schedule = schedule ?? _TimerTask.new;
  final NotesRepository repository;
  final DateTime Function() clock;
  final NotesSchedule schedule;
  final void Function(Object, StackTrace)? onError;
  static const pollInterval = Duration(seconds: 60);
  static const focusCoalescing = Duration(seconds: 10);
  static const retryIntervals = [5, 10, 20, 40, 80, 160];
  String? _account;
  bool _visible = true;
  bool _disposed = false;
  int _generation = 0;
  Future<void>? _running;
  String? _runningAccount;
  bool _followup = false;
  bool _manual = false;
  bool _writes = false;
  bool _capabilities = false;
  bool _readWasOffline = false;
  int _accountRetryCount = 0;
  DateTime? _completed;
  NotesScheduledTask? _poll;
  NotesScheduledTask? _retry;

  void setActiveAccount(String? id) {
    if (_disposed || id == _account) return;
    _generation++;
    _account = id;
    _poll?.cancel();
    _poll = null;
    _retry?.cancel();
    _retry = null;
    _followup = false;
    _manual = false;
    _writes = false;
    _capabilities = false;
    _completed = null;
    _accountRetryCount = 0;
    _readWasOffline = false;
    _armPoll();
  }

  void setVisible(bool visible) {
    if (_disposed || visible == _visible) return;
    _visible = visible;
    _poll?.cancel();
    _poll = null;
    if (visible) {
      _background(NotesSyncTrigger.focus);
      _armPoll();
    }
  }

  void focused() => _background(NotesSyncTrigger.focus);

  Future<void> request(NotesSyncTrigger trigger) {
    if (_disposed || _account == null) return Future.value();
    if (_running != null && _runningAccount != _account) {
      final generation = _generation;
      return _running!.then(
        (_) => generation == _generation && !_disposed
            ? request(trigger)
            : Future<void>.value(),
      );
    }
    if ((trigger == NotesSyncTrigger.focus ||
            trigger == NotesSyncTrigger.poll) &&
        !_visible) {
      return Future.value();
    }
    if (trigger == NotesSyncTrigger.focus &&
        _completed != null &&
        clock().difference(_completed!) < focusCoalescing) {
      return _running ?? Future.value();
    }
    final writes = {
      NotesSyncTrigger.opening,
      NotesSyncTrigger.localChange,
      NotesSyncTrigger.manual,
      NotesSyncTrigger.retry,
    }.contains(trigger);
    _writes |= writes;
    _manual |= trigger == NotesSyncTrigger.manual;
    _capabilities |= {
      NotesSyncTrigger.opening,
      NotesSyncTrigger.manual,
      NotesSyncTrigger.recovery,
    }.contains(trigger);
    if (_running != null) {
      if (writes) {
        _followup = true;
      }
      return _running!;
    }
    final id = _account!;
    final generation = _generation;
    _runningAccount = id;
    late final Future<void> task;
    task = _run(id, generation).whenComplete(() {
      if (identical(_running, task)) {
        _running = null;
        _runningAccount = null;
      }
      if (_disposed) return;
      if (generation == _generation) {
        _armRetry();
        _armPoll();
      }
    });
    _running = task;
    return task;
  }

  Future<void> _run(String id, int generation) async {
    do {
      _followup = false;
      final manual = _manual;
      final writes = _writes;
      final capabilities = _capabilities;
      _manual = false;
      _writes = false;
      _capabilities = false;
      if (manual) {
        _accountRetryCount = 0;
        await repository.retryWrites(id);
      }
      await repository.synchronize(
        id,
        allowWrites: true,
        onlyFreshWrites: !writes,
        refreshCapabilities: capabilities,
      );
      if (_disposed ||
          generation != _generation ||
          repository.accountById(id) == null) {
        return;
      }
      final error = repository.accountError(id);
      if (error?.code == NotesFailureCode.network) _readWasOffline = true;
      if (error == null) {
        _completed = clock();
        if (_readWasOffline) {
          _readWasOffline = false;
          _accountRetryCount = 0;
          await repository.recoverNetworkWrites(id);
          _writes = true;
          _capabilities = true;
          _followup = true;
        }
      }
      await repository.refreshDisplayedMedia(force: manual);
    } while (_followup && !_disposed && generation == _generation);
  }

  void _armPoll() {
    if (_disposed || !_visible || _account == null || _poll != null) return;
    final generation = _generation;
    _poll = schedule(pollInterval, () {
      _poll = null;
      if (_disposed || generation != _generation) return;
      // Authenticated collection reads are also bounded connectivity probes.
      _background(
        _readWasOffline ? NotesSyncTrigger.recovery : NotesSyncTrigger.poll,
      );
      _armPoll();
    });
  }

  void _armRetry() {
    final id = _account;
    if (_disposed || id == null || _retry != null) return;
    final accountFailure = repository.accountError(id);
    final accountRetry =
        accountFailure?.retryable == true &&
        _accountRetryCount < retryIntervals.length;
    final retryable = repository.hasRetryableWork(id);
    if (!accountRetry && !retryable) return;
    final counts =
        repository.notes
            .where(
              (n) =>
                  n.accountId == id &&
                  n.failureCode != null &&
                  n.retryCount > 0 &&
                  n.retryCount <= 6 &&
                  {
                    NotesFailureCode.network,
                    NotesFailureCode.server,
                    NotesFailureCode.locked,
                    NotesFailureCode.throttled,
                  }.contains(n.failureCode),
            )
            .map((n) => n.retryCount - 1)
            .toList()
          ..sort();
    final attempt = accountRetry
        ? _accountRetryCount++
        : counts.firstOrNull ?? 0;
    var delay = Duration(seconds: retryIntervals[attempt.clamp(0, 5)]);
    final deadline = repository.writeDeadline(id);
    if (deadline != null && deadline.difference(clock()) > delay) {
      delay = deadline.difference(clock());
    }
    final generation = _generation;
    _retry = schedule(delay, () {
      _retry = null;
      if (!_disposed && generation == _generation) {
        _background(NotesSyncTrigger.retry);
      }
    });
  }

  void _background(NotesSyncTrigger trigger) {
    unawaited(
      request(trigger).catchError((Object error, StackTrace stack) {
        onError?.call(error, stack);
      }),
    );
  }

  void removeAccount(String id) {
    if (_account == id) setActiveAccount(null);
  }

  void dispose() {
    _disposed = true;
    _generation++;
    _poll?.cancel();
    _retry?.cancel();
    _account = null;
    _followup = false;
  }
}
