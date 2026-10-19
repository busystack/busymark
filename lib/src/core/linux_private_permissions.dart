import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';

typedef _OpenNative = Int32 Function(Pointer<Utf8>, Int32);
typedef _OpenDart = int Function(Pointer<Utf8>, int);
typedef _FchmodNative = Int32 Function(Int32, Uint32);
typedef _FchmodDart = int Function(int, int);
typedef _ChmodNative = Int32 Function(Pointer<Utf8>, Uint32);
typedef _ChmodDart = int Function(Pointer<Utf8>, int);
typedef _CloseNative = Int32 Function(Int32);
typedef _CloseDart = int Function(int);
typedef _ErrnoNative = Pointer<Int32> Function();
typedef _ErrnoDart = Pointer<Int32> Function();

/// Restricts an existing Linux state inode without launching a subprocess.
/// O_NOFOLLOW rejects final-component symlinks; fchmod applies to the opened
/// inode even if another process replaces the pathname in the meantime.
final class LinuxPrivatePermissions {
  LinuxPrivatePermissions._() : _library = 'libc.so.6';

  /// Native barrier/error fixture only; production always selects libc.
  LinuxPrivatePermissions.forTesting({required String nativeLibrary})
    : _library = nativeLibrary;

  static final instance = LinuxPrivatePermissions._();
  final String _library;

  // At most one native worker is active per calling isolate. UI transaction
  // queues await admission/completion; no operation is dropped or cancelled.
  // Isolate.run retires its worker after each operation, including failures,
  // so an idle permission service cannot keep application shutdown alive.
  static Future<void> _tail = Future<void>.value();

  Future<void> restrict(String path, {required bool directory}) async {
    if (path.contains('\u0000')) {
      throw FileSystemException('Invalid application state path', path);
    }
    final operation = _tail.then(
      (_) => _restrictOffIsolate(path, directory, _library),
    );
    _tail = operation.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    await operation;
  }
}

// Explicit inputs prevent a closure from transferring a service, transaction,
// open descriptor or UI object. Construction, allocation, open/fchmod/close
// and error/errno handling all execute together on the worker isolate.
Future<void> _restrictOffIsolate(String path, bool directory, String library) =>
    Isolate.run(
      () => _NativePermissions(library).restrict(path, directory: directory),
      debugName: 'busymark-private-permissions',
    );

final class _NativePermissions {
  _NativePermissions(String library) {
    final libc = DynamicLibrary.open(library);
    _open = libc.lookupFunction<_OpenNative, _OpenDart>('open');
    _fchmod = libc.lookupFunction<_FchmodNative, _FchmodDart>('fchmod');
    _chmod = libc.lookupFunction<_ChmodNative, _ChmodDart>('chmod');
    _close = libc.lookupFunction<_CloseNative, _CloseDart>('close');
    _errno = libc.lookupFunction<_ErrnoNative, _ErrnoDart>('__errno_location');
  }

  late final _OpenDart _open;
  late final _FchmodDart _fchmod;
  late final _ChmodDart _chmod;
  late final _CloseDart _close;
  late final _ErrnoDart _errno;

  void restrict(String path, {required bool directory}) {
    if (path.contains('\u0000')) {
      throw FileSystemException('Invalid application state path', path);
    }
    // Linux UAPI: O_RDONLY | O_NONBLOCK | O_CLOEXEC | O_NOFOLLOW, optionally
    // O_DIRECTORY. O_NONBLOCK prevents an unexpected FIFO from blocking GTK.
    const flags = 0x800 | 0x80000 | 0x20000;
    final nativePath = path.toNativeUtf8();
    var descriptor = -1;
    var pathDescriptor = false;
    int? error;
    try {
      descriptor = _open(nativePath, flags | (directory ? 0x10000 : 0));
      if (descriptor < 0 && directory && _errno().value == 13) {
        // chmod does not require read permission on an owned directory. Pin
        // that inode without opening it for I/O. O_DIRECTORY | O_NOFOLLOW
        // rejects a final symlink even though O_PATH alone would retain it.
        descriptor = _open(nativePath, 0x200000 | 0x80000 | 0x20000 | 0x10000);
        pathDescriptor = true;
      }
      if (descriptor < 0) error = _errno().value;
    } finally {
      malloc.free(nativePath);
    }
    if (error != null) _fail(path, error);
    try {
      if (pathDescriptor) {
        // fchmod rejects O_PATH descriptors. This procfs magic link resolves
        // the held inode, not the original (possibly replaced) pathname. Keep
        // the descriptor open until chmod completes; unavailable procfs fails
        // the transaction rather than falling back to an unpinned path.
        final heldPath = '/proc/self/fd/$descriptor'.toNativeUtf8();
        try {
          if (_chmod(heldPath, 448) != 0) error = _errno().value;
        } finally {
          malloc.free(heldPath);
        }
      } else if (_fchmod(descriptor, directory ? 448 : 384) != 0) {
        error = _errno().value;
      }
    } finally {
      if (_close(descriptor) != 0) error ??= _errno().value;
    }
    if (error != null) _fail(path, error);
  }

  Never _fail(String path, int code) => throw FileSystemException(
    'Could not restrict application state permissions',
    path,
    OSError('Native permission operation failed', code),
  );
}
