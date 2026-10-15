import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

typedef _OpenNative = Int32 Function(Pointer<Utf8>, Int32);
typedef _OpenDart = int Function(Pointer<Utf8>, int);
typedef _FchmodNative = Int32 Function(Int32, Uint32);
typedef _FchmodDart = int Function(int, int);
typedef _CloseNative = Int32 Function(Int32);
typedef _CloseDart = int Function(int);
typedef _ErrnoNative = Pointer<Int32> Function();
typedef _ErrnoDart = Pointer<Int32> Function();

/// Restricts an existing Linux state inode without launching a subprocess.
/// O_NOFOLLOW rejects final-component symlinks; fchmod applies to the opened
/// inode even if another process replaces the pathname in the meantime.
final class LinuxPrivatePermissions {
  LinuxPrivatePermissions._() {
    final libc = DynamicLibrary.open('libc.so.6');
    _open = libc.lookupFunction<_OpenNative, _OpenDart>('open');
    _fchmod = libc.lookupFunction<_FchmodNative, _FchmodDart>('fchmod');
    _close = libc.lookupFunction<_CloseNative, _CloseDart>('close');
    _errno = libc.lookupFunction<_ErrnoNative, _ErrnoDart>('__errno_location');
  }

  static final instance = LinuxPrivatePermissions._();
  late final _OpenDart _open;
  late final _FchmodDart _fchmod;
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
    final int descriptor;
    try {
      descriptor = _open(nativePath, flags | (directory ? 0x10000 : 0));
    } finally {
      malloc.free(nativePath);
    }
    if (descriptor < 0) _fail(path, _errno().value);
    int? error;
    try {
      if (_fchmod(descriptor, directory ? 448 : 384) != 0) {
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
