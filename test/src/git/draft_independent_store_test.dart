import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:busymark/src/app/git_dismissal.dart';
import 'package:busymark/src/app/window_control_service.dart';
import 'package:window_manager/window_manager.dart';
import 'package:busymark/src/git/application/shared_git_integration.dart';
import 'package:busystack_git_flutter/busystack_git_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../busystack_git_flutter/test/support/presentation_fixture.dart'
    as fixture;

GitSession _session(GitDraftStore store) {
  final base = fixture.host();
  return GitSession(
    client: fixture.FixtureClient(),
    repository: fixture.repo,
    host: GitHost(
      present: base.present,
      openDocument: base.openDocument,
      prepareMutation: base.prepareMutation,
      chooseDirectory: base.chooseDirectory,
      notify: base.notify,
      drafts: store,
    ),
  );
}

void main() {
  test(
    'independent concrete stores cannot clear another window newer amend',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'mark-draft-cas-',
      );
      addTearDown(() => directory.delete(recursive: true));
      BusyMarkGitDraftStore makeStore() =>
          BusyMarkGitDraftStore(directory: () async => directory);
      final first = _session(makeStore()), second = _session(makeStore());
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      final normalKey = fixture.repo.presentationKey;
      final amendKey = '$normalKey:amend:${'a' * 40}';
      first.setDraft('independently preserved normal A');
      final submitted = first.setMessageDraft(amendKey, 'submitted amend B');
      await first.flushMessageDrafts();
      await second.readMessageDraft(amendKey);
      second.setMessageDraft(amendKey, 'newer amend C in second window');
      await second.flushMessageDrafts();

      // The first isolate's revision did not change, although the actual file did.
      expect(await first.clearMessageDraft(submitted), isFalse);
      await first.flushMessageDrafts();
      final reopened = makeStore();
      expect(
        await reopened.read(normalKey),
        'independently preserved normal A',
      );
      expect(await reopened.read(amendKey), 'newer amend C in second window');
      expect(
        first.draftFailure,
        isNotNull,
        reason: 'A durable ownership conflict must be explicitly recoverable.',
      );
    },
  );

  test(
    'delayed concrete older write cannot replace newer independent store',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'mark-draft-order-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final firstPathRequested = Completer<void>();
      final releaseFirstPath = Completer<Directory>();
      var calls = 0;
      final first = BusyMarkGitDraftStore(
        directory: () {
          if (++calls == 1) {
            firstPathRequested.complete();
            return releaseFirstPath.future;
          }
          return Future.value(directory);
        },
      );
      final second = BusyMarkGitDraftStore(directory: () async => directory);
      final older = expectLater(
        first.write('same-worktree', 'older B'),
        throwsA(isA<GitDraftConflict>()),
      );
      await firstPathRequested.future;
      await second.write('same-worktree', 'newer C');
      releaseFirstPath.complete(directory);
      await older;
      final reopened = BusyMarkGitDraftStore(directory: () async => directory);
      expect(await reopened.read('same-worktree'), 'newer C');
    },
  );

  test(
    'conditional consume delayed before disk leaves newer window text',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'mark-clear-race-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final entered = Completer<void>();
      final release = Completer<Directory>();
      var delay = false;
      final firstStore = BusyMarkGitDraftStore(
        directory: () {
          if (delay) {
            delay = false;
            entered.complete();
            return release.future;
          }
          return Future.value(directory);
        },
      );
      final first = _session(firstStore);
      final second = _session(
        BusyMarkGitDraftStore(directory: () async => directory),
      );
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      final submitted = first.setMessageDraft('amend:old-head', 'submitted B');
      await first.flushMessageDrafts();
      delay = true;
      final consuming = first.clearMessageDraft(submitted);
      await entered.future;
      await second.readMessageDraft('amend:old-head');
      second.setMessageDraft('amend:old-head', 'newer C');
      await second.flushMessageDrafts();
      release.complete(directory);
      expect(await consuming, isFalse);
      final reopened = BusyMarkGitDraftStore(directory: () async => directory);
      expect(await reopened.read('amend:old-head'), 'newer C');
      expect(first.messageDraft('amend:old-head').text, 'newer C');
    },
  );

  test(
    'conflicting local message requires explicit saved-message review',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'mark-review-race-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final first = _session(
        BusyMarkGitDraftStore(directory: () async => directory),
      );
      final second = _session(
        BusyMarkGitDraftStore(directory: () async => directory),
      );
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      final key = fixture.repo.presentationKey;
      second.setMessageDraft(key, 'saved C');
      await second.flushMessageDrafts();
      first.setMessageDraft(key, 'local B');
      await first.flushMessageDrafts();
      expect(first.draftFailure, isNotNull);
      expect(first.hasUnpersistedMessageDrafts, isTrue);
      final review = (await first.reviewMessageDraft(key))!;
      expect(review.local.text, 'local B');
      expect(review.saved.text, 'saved C');
      final reopened = BusyMarkGitDraftStore(directory: () async => directory);
      expect(await reopened.read(key), 'saved C');
      expect(await first.resolveMessageDraft(review, useSaved: false), isTrue);
      expect(await reopened.read(key), 'local B');
      expect(first.hasUnpersistedMessageDrafts, isFalse);
      expect(first.draftFailure, isNull);
    },
  );

  test(
    'reopen discovers saved amend owners after stale preference writes',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'mark-amend-owner-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final firstStore = BusyMarkGitDraftStore(
        directory: () async => directory,
      );
      final secondStore = BusyMarkGitDraftStore(
        directory: () async => directory,
      );
      final first = _session(firstStore), second = _session(secondStore);
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      final key = fixture.repo.presentationKey;
      final oldHead = 'a' * 40, otherHead = 'b' * 40;
      final amend = '$key:amend:$oldHead';
      first.setDraft('independent normal A');
      final submitted = first.setMessageDraft(amend, 'submitted B');
      await first.flushMessageDrafts();
      await firstStore.writeViewState(key, {
        'commitAmendDraftTargets': [oldHead],
        'split': 0.4,
      });
      await second.readMessageDraft(amend);
      second.setMessageDraft(amend, 'newer C');
      second.setMessageDraft(
        '$key:amend:$otherHead',
        'other reviewed target D',
      );
      await second.flushMessageDrafts();
      expect(await first.clearMessageDraft(submitted), isFalse);
      // An old window can later persist its cleared/obsolete preference list.
      await firstStore.writeViewState(key, {
        'commitAmendDraftTargets': <String>[],
        'split': 0.6,
      });
      final reopened = BusyMarkGitDraftStore(directory: () async => directory);
      final restored = (await reopened.readViewState(key))!;
      expect(restored['split'], 0.6);
      expect(
        restored['commitAmendDraftTargets'],
        unorderedEquals([oldHead, otherHead]),
      );
      expect(await reopened.read(amend), 'newer C');
      expect(
        await reopened.read('$key:amend:$otherHead'),
        'other reviewed target D',
      );
      expect(await reopened.read(key), 'independent normal A');
    },
  );

  test(
    'independent stores migrate existing plaintext and preserve preferences',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'mark-draft-old-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final old = File('${directory.path}/worktree-amend:head.txt');
      await old.writeAsString('old message\r\nwithout final newline');
      final first = BusyMarkGitDraftStore(directory: () async => directory);
      final second = BusyMarkGitDraftStore(directory: () async => directory);
      final observed = await first.readVersioned('worktree-amend:head');
      expect(observed.text, 'old message\r\nwithout final newline');
      expect(observed.version, isNot(GitStoredDraft.absentVersion));
      expect(
        (await second.readVersioned('worktree-amend:head')).version,
        observed.version,
      );
      final result = await first.compareAndWrite(
        'worktree-amend:head',
        expectedVersion: observed.version,
        text: 'new message',
      );
      expect(result.written, isTrue);
      expect(await second.read('worktree-amend:head'), 'new message');
      await first.writeViewState('worktree', {'split': 0.4});
      await second.writeViewState('worktree', {'split': 0.6});
      await first.writeViewState('worktree', {'split': 0.7});
      expect(await second.readViewState('worktree'), {
        'split': 0.7,
        'commitAmendDraftTargets': <String>[],
      });
      expect(await second.read('worktree-amend:head'), 'new message');
    },
  );

  test(
    'actual stores in independent isolates serialize durable ownership',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'mark-draft-iso-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final store = BusyMarkGitDraftStore(directory: () async => directory);
      await store.write('worktree', 'original A');
      final first = ReceivePort(), second = ReceivePort();
      addTearDown(first.close);
      addTearDown(second.close);
      final firstMessages = StreamIterator<dynamic>(first);
      final secondMessages = StreamIterator<dynamic>(second);
      final isolates = await Future.wait([
        Isolate.spawn(_storeIsolate, [directory.path, first.sendPort]),
        Isolate.spawn(_storeIsolate, [directory.path, second.sendPort]),
      ]);
      addTearDown(() {
        for (final isolate in isolates) {
          isolate.kill(priority: Isolate.immediate);
        }
      });
      expect(await firstMessages.moveNext(), isTrue);
      expect(await secondMessages.moveNext(), isTrue);
      final left = firstMessages.current as List;
      final right = secondMessages.current as List;
      expect(left[1], right[1]);
      expect(left[2], 'original A');
      expect(right[2], 'original A');
      (left[0] as SendPort).send('newer B');
      (right[0] as SendPort).send('newer C');
      expect(await firstMessages.moveNext(), isTrue);
      expect(await secondMessages.moveNext(), isTrue);
      final leftResult = firstMessages.current as List;
      final rightResult = secondMessages.current as List;
      expect(
        [leftResult[0], rightResult[0]].where((value) => value == true),
        hasLength(1),
      );
      final winner = leftResult[0] == true ? 'newer B' : 'newer C';
      expect(leftResult[1], winner);
      expect(rightResult[1], winner);
      expect(await store.read('worktree'), winner);
      expect(
        directory.listSync().whereType<File>().where(
          (file) => file.path.endsWith('.pending'),
        ),
        isEmpty,
      );
    },
  );

  for (final action in <WindowCloseAction?>[
    null,
    WindowCloseAction.save,
    WindowCloseAction.discard,
  ]) {
    test(
      'normal window $action waits for draft I/O before native close',
      () async {
        final directory = await Directory.systemTemp.createTemp(
          'mark-close-io-',
        );
        addTearDown(() => directory.delete(recursive: true));
        final requested = Completer<void>();
        final release = Completer<Directory>();
        final store = BusyMarkGitDraftStore(
          directory: () {
            if (!requested.isCompleted) requested.complete();
            return release.future;
          },
        );
        final registry = BusyMarkGitDraftFlushRegistry()..register(store.flush);
        final native = _NativeWindow();
        final service = WindowControlService(nativeWindow: native);
        addTearDown(service.dispose);
        await service.initialize();
        final writing = store.write('worktree', 'recoverable before teardown');
        await requested.future;
        final close = service.handleCloseRequest(
          hasUnsavedChanges: action != null,
          confirmCloseWithUnsavedChanges: true,
          showCloseDialog: () async => action,
          saveChanges: () async => true,
          beforeClose: registry.flush,
          discardChanges: registry.flush,
        );
        await Future<void>.delayed(Duration.zero);
        expect(native.closes, 0);
        expect(native.prevented, isTrue);
        release.complete(directory);
        await writing;
        await close;
        expect(native.closes, 1);
        expect(native.prevented, isFalse);
        final fresh = BusyMarkGitDraftStore(directory: () async => directory);
        expect(await fresh.read('worktree'), 'recoverable before teardown');
      },
    );
  }

  test(
    'retiring a scope during another flush never calls its disposed host',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'mark-retire-flush-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final store = BusyMarkGitDraftStore(directory: () async => directory);
      final session = _session(store);
      session.setDraft('retired pending message');
      final registry = BusyMarkGitDraftFlushRegistry();
      final entered = Completer<void>(), release = Completer<void>();
      registry.register(() {
        entered.complete();
        return release.future;
      });
      final unregister = registry.register(
        () => throw StateError('Disposed widget ref must not be accessed'),
        sessions: () => [session],
      );
      final flushing = registry.flush();
      await entered.future;
      unregister();
      session.dispose();
      release.complete();
      await flushing;
      expect(registry.liveSessions(), isEmpty);
      expect(
        await store.read(fixture.repo.presentationKey),
        'retired pending message',
      );
    },
  );

  test('window persistence flush waits for concrete store work', () async {
    final directory = await Directory.systemTemp.createTemp('mark-draft-exit-');
    addTearDown(() => directory.delete(recursive: true));
    final requested = Completer<void>();
    final release = Completer<Directory>();
    final store = BusyMarkGitDraftStore(
      directory: () {
        if (!requested.isCompleted) requested.complete();
        return release.future;
      },
    );
    final registry = BusyMarkGitDraftFlushRegistry();
    final unregister = registry.register(store.flush);
    final writing = store.write('worktree', 'pending message');
    await requested.future;
    var flushed = false;
    final closing = registry.flush().then((_) => flushed = true);
    await Future<void>.delayed(Duration.zero);
    expect(flushed, isFalse);
    release.complete(directory);
    await writing;
    await closing;
    expect(flushed, isTrue);
    final fresh = BusyMarkGitDraftStore(directory: () async => directory);
    expect(await fresh.read('worktree'), 'pending message');
    unregister();
    await registry.flush();
  });
}

Future<void> _storeIsolate(List<Object> arguments) async {
  final directory = Directory(arguments[0] as String);
  final reply = arguments[1] as SendPort;
  final requests = ReceivePort();
  final store = BusyMarkGitDraftStore(directory: () async => directory);
  try {
    final observed = await store.readVersioned('worktree');
    reply.send([requests.sendPort, observed.version, observed.text]);
    final message = await requests.first as String;
    final result = await store.compareAndWrite(
      'worktree',
      expectedVersion: observed.version,
      text: message,
    );
    await store.flush();
    reply.send([result.written, result.current.text]);
  } finally {
    requests.close();
  }
}

final class _NativeWindow implements NativeWindowController {
  bool prevented = false;
  int closes = 0;
  @override
  Future<void> setPreventClose(bool value) async => prevented = value;
  @override
  Future<void> close() async {
    closes++;
  }

  @override
  Future<bool> isFullScreen() async => false;
  @override
  Future<void> setFullScreen(bool value) async {}
  @override
  void addListener(WindowListener listener) {}
  @override
  void removeListener(WindowListener listener) {}
}
