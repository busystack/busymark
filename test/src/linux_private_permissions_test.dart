import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:busymark/src/core/linux_private_permissions.dart';
import 'package:busymark/src/app/window_control_service.dart';
import 'package:busymark/src/workspace/session_persistence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:window_manager/window_manager.dart';

typedef _IntNative = Int32 Function();
typedef _IntDart = int Function();
typedef _ConfigureNative = Int32 Function(Int32);
typedef _ConfigureDart = int Function(int);

void main() {
  if (!Platform.isLinux) return;
  late Directory root;
  late LinuxPrivatePermissions permissions;
  late _ConfigureDart configure;
  late _IntDart entered, opens, closes, release, workerTid, currentTid;
  setUpAll(() async {
    root = await Directory.systemTemp.createTemp('bm-permission-worker-');
    final library = '${root.path}/barrier.so';
    final build = await Process.run('cc', [
      '-shared',
      '-fPIC',
      '-std=c11',
      '-Wall',
      '-Werror',
      'test/support/private_permissions_barrier.c',
      '-ldl',
      '-o',
      library,
    ]);
    expect(build.exitCode, 0, reason: '${build.stdout}\n${build.stderr}');
    final native = DynamicLibrary.open(library);
    configure = native.lookupFunction<_ConfigureNative, _ConfigureDart>(
      'permission_test_configure',
    );
    _IntDart function(String name) =>
        native.lookupFunction<_IntNative, _IntDart>('permission_test_$name');
    entered = function('entered');
    opens = function('opens');
    closes = function('closes');
    release = function('release');
    workerTid = function('worker_tid');
    currentTid = function('current_tid');
    permissions = LinuxPrivatePermissions.forTesting(nativeLibrary: library);
  });
  tearDownAll(() async {
    configure(0);
    await root.delete(recursive: true);
  });

  test(
    'actual native fchmod can block while UI progresses; admission is serial',
    () async {
      expect(configure(1), 0);
      final first = await File('${root.path}/first').writeAsString('first');
      final second = await File('${root.path}/second').writeAsString('second');
      var completed = false;
      final operation = permissions.restrict(first.path, directory: false).then(
        (_) {
          completed = true;
        },
      );
      final queued = permissions.restrict(second.path, directory: false);
      final nativeWindow = _NativeWindow();
      final window = WindowControlService(nativeWindow: nativeWindow);
      final closing = window.handleCloseRequest(
        hasUnsavedChanges: false,
        confirmCloseWithUnsavedChanges: true,
        showCloseDialog: () async => WindowCloseAction.cancel,
        saveChanges: () async => false,
        beforeClose: () async {
          await operation;
          await queued;
        },
      );
      try {
        final deadline = Stopwatch()..start();
        while (entered() == 0) {
          expect(deadline.elapsed, lessThan(const Duration(seconds: 10)));
          await Future<void>.delayed(const Duration(milliseconds: 1));
        }
        final progress = Completer<void>();
        Timer.run(progress.complete);
        await progress.future;
        expect(completed, isFalse);
        expect(opens(), 1, reason: 'A second native worker must not enter');
        expect(closes(), 0);
        expect(workerTid(), isNot(currentTid()));
        expect(nativeWindow.closes, 0);
      } finally {
        expect(release(), 1);
        await operation;
        await queued;
        await closing;
        window.dispose();
      }
      expect(nativeWindow.closes, 1);
      expect(opens(), 2);
      expect(closes(), 2);
      expect((await first.stat()).mode & 511, 384);
      expect((await second.stat()).mode & 511, 384);
    },
  );

  for (final mode in [2, 3]) {
    test(
      'native failure $mode closes descriptor and does not poison queue',
      () async {
        expect(configure(mode), 0);
        final file = await File(
          '${root.path}/failure-$mode',
        ).writeAsString('data');
        await expectLater(
          permissions.restrict(file.path, directory: false),
          throwsA(isA<FileSystemException>()),
        );
        expect(closes(), 1);
        expect(configure(0), 0);
        await permissions.restrict(file.path, directory: false);
        expect(closes(), 1);
      },
    );
  }

  test(
    'unreadable directory uses its held inode after path replacement',
    () async {
      expect(configure(4), 0);
      final directory = await Directory('${root.path}/held').create();
      final moved = '${root.path}/moved';
      final operation = permissions.restrict(directory.path, directory: true);
      try {
        final deadline = Stopwatch()..start();
        while (entered() == 0) {
          expect(deadline.elapsed, lessThan(const Duration(seconds: 10)));
          await Future<void>.delayed(const Duration(milliseconds: 1));
        }
        // The actual native chmod is pending on a worker, with its O_PATH fd
        // admitted. Replacing the original path must not redirect protection.
        expect(workerTid(), isNot(currentTid()));
        expect(opens(), 1);
        await directory.rename(moved);
        await directory.create();
        expect(
          (await Process.run('chmod', ['755', directory.path])).exitCode,
          0,
        );
      } finally {
        expect(release(), 1);
        await operation;
      }
      expect((await Directory(moved).stat()).mode & 511, 448);
      expect((await directory.stat()).mode & 511, 493);
      expect(closes(), 1);
    },
  );

  test('unreadable file uses its held inode after path replacement', () async {
    expect(configure(4), 0);
    final file = await File('${root.path}/held-file').writeAsString('held');
    final moved = '${root.path}/moved-file';
    final operation = permissions.restrict(file.path, directory: false);
    try {
      final deadline = Stopwatch()..start();
      while (entered() == 0) {
        expect(deadline.elapsed, lessThan(const Duration(seconds: 10)));
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
      expect(workerTid(), isNot(currentTid()));
      expect(opens(), 1);
      await file.rename(moved);
      await file.writeAsString('replacement');
      expect((await Process.run('chmod', ['644', file.path])).exitCode, 0);
    } finally {
      expect(release(), 1);
      await operation;
    }
    expect((await File(moved).stat()).mode & 511, 384);
    expect((await file.stat()).mode & 511, 420);
    expect(await file.readAsString(), 'replacement');
    expect(closes(), 1);
  });

  for (final directory in [true, false]) {
    for (final mode in [5, 6, 7, 8]) {
      test(
        'fallback directory=$directory failure $mode closes fd and preserves queue',
        () async {
          expect(configure(mode), 0);
          final path = '${root.path}/failure-$directory-$mode';
          if (directory) {
            await Directory(path).create();
          } else {
            await File(path).writeAsString('data');
          }
          await expectLater(
            permissions.restrict(path, directory: directory),
            throwsA(isA<FileSystemException>()),
          );
          expect(opens(), 1);
          expect(closes(), 1);
          expect(configure(0), 0);
          await permissions.restrict(path, directory: directory);
          expect(closes(), 1);
        },
      );
    }
  }

  test(
    'file fallback rejects an O_PATH descriptor to a final symlink',
    () async {
      expect(configure(4), 0);
      final file = await File(
        '${root.path}/linked-file',
      ).writeAsString('target');
      expect((await Process.run('chmod', ['644', file.path])).exitCode, 0);
      final link = await Link('${root.path}/file-link').create(file.path);
      await expectLater(
        permissions.restrict(link.path, directory: false),
        throwsA(
          isA<FileSystemException>().having(
            (error) => error.osError?.errorCode,
            'symlink rejection',
            40,
          ),
        ),
      );
      expect(opens(), 1);
      expect(closes(), 1);
      expect(entered(), 0);
      expect((await file.stat()).mode & 511, 420);
      expect(await link.target(), file.path);
      expect(await file.readAsString(), 'target');
      expect(configure(0), 0);
    },
  );

  test('directory fallback rejects a final symlink', () async {
    expect(configure(4), 0);
    final directory = await Directory('${root.path}/linked-directory').create();
    expect((await Process.run('chmod', ['755', directory.path])).exitCode, 0);
    final link = await Link(
      '${root.path}/directory-link',
    ).create(directory.path);
    await expectLater(
      permissions.restrict(link.path, directory: true),
      throwsA(isA<FileSystemException>()),
    );
    expect(opens(), 0);
    expect(entered(), 0);
    expect((await directory.stat()).mode & 511, 493);
    expect(configure(0), 0);
  });

  test('rejected paths leave their target and worker queue intact', () async {
    expect(configure(0), 0);
    final file = await File('${root.path}/target').writeAsString('unchanged');
    final before = (await file.stat()).mode;
    final link = await Link('${root.path}/link').create(file.path);
    for (final path in [
      link.path,
      '${file.path}\u0000suffix',
      '${root.path}/missing',
    ]) {
      await expectLater(
        permissions.restrict(path, directory: false),
        throwsA(isA<FileSystemException>()),
      );
    }
    expect(opens(), 0);
    expect((await file.stat()).mode, before);
    expect(await file.readAsString(), 'unchanged');
    await permissions.restrict(root.path, directory: true);
    expect((await root.stat()).mode & 511, 448);
  });

  test(
    'concurrent atomic publications await protection and leave no staging state',
    () async {
      await Future.wait([
        for (var i = 0; i < 20; i++)
          writeAtomicJson(File('${root.path}/states/$i.json'), {'revision': i}),
      ]);
      final states = Directory('${root.path}/states');
      expect((await states.list().toList()), hasLength(20));
      expect((await states.stat()).mode & 511, 448);
      for (final entity in await states.list().toList()) {
        expect(entity, isA<File>());
        expect((await entity.stat()).mode & 511, 384);
      }
    },
  );
}

class _NativeWindow implements NativeWindowController {
  int closes = 0;
  @override
  Future<void> close() async => closes++;
  @override
  Future<void> setPreventClose(bool value) async {}
  @override
  Future<bool> isFullScreen() async => false;
  @override
  Future<void> setFullScreen(bool value) async {}
  @override
  void addListener(WindowListener listener) {}
  @override
  void removeListener(WindowListener listener) {}
}
