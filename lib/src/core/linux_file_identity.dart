import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

typedef _StatxNative =
    Int32 Function(Int32, Pointer<Utf8>, Int32, Uint32, Pointer<Uint8>);
typedef _StatxDart = int Function(int, Pointer<Utf8>, int, int, Pointer<Uint8>);

/// Durable identity across rename, including birth time when supported. The
/// fixed 256-byte Linux statx ABI comes from linux/uapi/linux/stat.h; unlike
/// struct stat, its offsets do not vary between supported Linux architectures.
final class LinuxFileIdentity {
  LinuxFileIdentity._();
  static final _StatxDart? _statx = _load();
  static _StatxDart? _load() {
    if (!Platform.isLinux) return null;
    try {
      return DynamicLibrary.open(
        'libc.so.6',
      ).lookupFunction<_StatxNative, _StatxDart>('statx');
    } on ArgumentError {
      return null;
    }
  }

  /// Unsupported identity inspection returns null. Recovery must fail closed
  /// rather than infer identity from a pathname or matching document bytes.
  static String? read(String path) {
    final statx = _statx;
    if (statx == null) return null;
    final nativePath = path.toNativeUtf8();
    final buffer = calloc<Uint8>(256);
    try {
      // AT_FDCWD, AT_SYMLINK_NOFOLLOW, STATX_BASIC_STATS | STATX_BTIME.
      if (statx(-100, nativePath, 0x100, 0xfff, buffer) != 0) {
        throw FileSystemException('Cannot inspect filesystem identity', path);
      }
      final data = ByteData.sublistView(buffer.asTypedList(256));
      final mask = data.getUint32(0, Endian.host);
      if (mask & 0x100 == 0) return null; // STATX_INO must be real.
      final major = data.getUint32(0x88, Endian.host);
      final minor = data.getUint32(0x8c, Endian.host);
      final inode = data.getUint64(0x20, Endian.host);
      final birth = mask & 0x800 == 0
          ? ''
          : ':${data.getInt64(0x50, Endian.host)}:${data.getUint32(0x58, Endian.host)}';
      return '$major:$minor:$inode$birth';
    } finally {
      calloc.free(buffer);
      malloc.free(nativePath);
    }
  }
}
