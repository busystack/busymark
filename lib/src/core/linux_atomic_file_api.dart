import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

typedef _RenameAt2Native =
    Int32 Function(
      Int32 oldDirectory,
      Pointer<Utf8> oldPath,
      Int32 newDirectory,
      Pointer<Utf8> newPath,
      Uint32 flags,
    );
typedef _RenameAt2Dart =
    int Function(
      int oldDirectory,
      Pointer<Utf8> oldPath,
      int newDirectory,
      Pointer<Utf8> newPath,
      int flags,
    );
typedef _ErrnoLocationNative = Pointer<Int32> Function();
typedef _ErrnoLocationDart = Pointer<Int32> Function();
typedef _LinkNative =
    Int32 Function(Pointer<Utf8> oldPath, Pointer<Utf8> newPath);
typedef _LinkDart = int Function(Pointer<Utf8> oldPath, Pointer<Utf8> newPath);

/// Small Linux-only wrapper around atomic `renameat2` file exchanges.
///
/// Exchanging a staged file with its destination lets callers verify the exact
/// inode that was replaced and exchange it back without overwriting a
/// concurrent writer.
final class LinuxAtomicFileApi {
  LinuxAtomicFileApi._() {
    if (!Platform.isLinux) {
      return;
    }
    final library = DynamicLibrary.open('libc.so.6');
    _library = library;
    try {
      _renameAt2 = _library!.lookupFunction<_RenameAt2Native, _RenameAt2Dart>(
        'renameat2',
      );
    } on ArgumentError {
      _renameAt2 = null;
    }
    _errnoLocation = _library!
        .lookupFunction<_ErrnoLocationNative, _ErrnoLocationDart>(
          '__errno_location',
        );
    _link = _library!.lookupFunction<_LinkNative, _LinkDart>('link');
  }

  static const fileExistsError = 17;
  static const _invalidArgumentError = 22;
  static const _functionNotImplementedError = 38;
  static const _operationNotSupportedError = 95;
  static const _atCurrentWorkingDirectory = -100;
  static const _renameNoReplace = 1;
  static const _renameExchange = 2;
  static final instance = LinuxAtomicFileApi._();

  _RenameAt2Dart? _renameAt2;
  _ErrnoLocationDart? _errnoLocation;
  _LinkDart? _link;
  DynamicLibrary? _library;

  bool get isAvailable => _renameAt2 != null && _errnoLocation != null;

  /// Returns `null` on success, otherwise the Linux errno value.
  int? exchange(String firstPath, String secondPath) {
    final renameAt2 = _renameAt2;
    final errnoLocation = _errnoLocation;
    if (renameAt2 == null || errnoLocation == null) {
      return null;
    }
    final nativeFirstPath = firstPath.toNativeUtf8();
    final nativeSecondPath = secondPath.toNativeUtf8();
    try {
      final result = renameAt2(
        _atCurrentWorkingDirectory,
        nativeFirstPath,
        _atCurrentWorkingDirectory,
        nativeSecondPath,
        _renameExchange,
      );
      return result == 0 ? null : errnoLocation().value;
    } finally {
      malloc.free(nativeFirstPath);
      malloc.free(nativeSecondPath);
    }
  }

  /// Publishes [oldPath] at [newPath] without replacing an existing entity.
  ///
  /// Returns `null` on success, otherwise the Linux errno value.
  int? publishNoReplace(String oldPath, String newPath) {
    final errnoLocation = _errnoLocation;
    final link = _link;
    if (errnoLocation == null || link == null) {
      return _operationNotSupportedError;
    }
    final nativeOldPath = oldPath.toNativeUtf8();
    final nativeNewPath = newPath.toNativeUtf8();
    try {
      final renameAt2 = _renameAt2;
      if (renameAt2 != null) {
        final result = renameAt2(
          _atCurrentWorkingDirectory,
          nativeOldPath,
          _atCurrentWorkingDirectory,
          nativeNewPath,
          _renameNoReplace,
        );
        if (result == 0) {
          return null;
        }
        final errorNumber = errnoLocation().value;
        if (errorNumber != _invalidArgumentError &&
            errorNumber != _functionNotImplementedError &&
            errorNumber != _operationNotSupportedError) {
          return errorNumber;
        }
      }
      final result = link(nativeOldPath, nativeNewPath);
      return result == 0 ? null : errnoLocation().value;
    } finally {
      malloc.free(nativeOldPath);
      malloc.free(nativeNewPath);
    }
  }
}
