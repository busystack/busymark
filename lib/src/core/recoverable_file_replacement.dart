import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'atomic_file_exceptions.dart';
import 'linux_atomic_file_api.dart';
import 'linux_file_identity.dart';
import 'save_destination.dart';

/// Replacement for filesystems that offer no-replace rename but no exchange.
/// The original is recoverable by name during the gap between the renames.
Future<void> replaceFileWithoutExchange({
  required File staged,
  required SaveDestination destination,
  FutureOr<bool> Function(String)? acceptDisplaced,
  void Function()? checkBeforeCommit,
}) async {
  final target = destination.path;
  if (!destination.replacesRegularFile) {
    throw FileSystemException(
      'This filesystem requires atomic exchange to replace this entry',
      target,
    );
  }
  final api = LinuxAtomicFileApi.instance;
  final parent = p.dirname(target);
  final parentFd = api.openDirectory(parent);
  final parentHandle = '/proc/self/fd/$parentFd';
  final targetHandle = p.join(parentHandle, p.basename(target));
  int? stagedFd, recoveryFd, originalFd;
  Directory? recovery;
  var displaced = false;
  var published = false;
  try {
    if (!destination.acceptsParent(parentHandle)) {
      throw AtomicFileChangedException(target);
    }
    final parentInode = LinuxFileIdentity.version(
      parentHandle,
      followLinks: true,
    )!.inodeIdentity;
    // exFAT updates the directory's reported birth time on rename into it.
    // The open descriptor pins the inode so it cannot be reused.
    bool parentIsCurrent() =>
        LinuxFileIdentity.version(parent, followLinks: true)?.inodeIdentity ==
        parentInode;
    final stageParent = p.dirname(staged.absolute.path);
    stagedFd = api.openDirectory(stageParent);
    final stagedHandle = '/proc/self/fd/$stagedFd/${p.basename(staged.path)}';
    final stagedVersion = LinuxFileIdentity.version(stagedHandle);
    final recoveryDir = Directory(
      parentHandle,
    ).createTempSync('.busymark-recovery-');
    recovery = recoveryDir;
    recoveryFd = api.openDirectory(recoveryDir.path);
    final recoveryHandle = '/proc/self/fd/$recoveryFd/${p.basename(target)}';
    // Check flush support before changing the destination and persist both
    // directory entries before and after publishing the replacement.
    api.flushDirectory(parentFd, parent);
    api.flushDirectory(recoveryFd, recoveryDir.path);
    destination.requireCurrent(target);
    originalFd = api.pinEntry(targetHandle);
    final original = LinuxFileIdentity.version(
      '/proc/self/fd/$originalFd',
      followLinks: true,
    );
    final moveError = api.moveNoReplace(targetHandle, recoveryHandle);
    if (moveError == LinuxAtomicFileApi.fileMissingError) {
      throw AtomicFileChangedException(target);
    }
    if (moveError != null) {
      throw FileSystemException(
        'Could not secure the original for recoverable replacement',
        target,
        OSError('no-replace rename failed', moveError),
      );
    }
    displaced = true;

    try {
      api.flushDirectory(recoveryFd, recoveryDir.path);
      api.flushDirectory(parentFd, parent);
      final displacedVersion = LinuxFileIdentity.version(recoveryHandle);
      if (original == null ||
          displacedVersion?.identity != original.identity ||
          !destination.acceptsDisplacedFile(recoveryHandle)) {
        throw AtomicFileChangedException(
          target,
          cause: 'Original entry changed',
        );
      }
      if (await acceptDisplaced?.call(recoveryHandle) == false ||
          LinuxFileIdentity.version(recoveryHandle) != displacedVersion) {
        throw AtomicFileChangedException(
          target,
          cause: 'Original content changed',
        );
      }
      if (stagedVersion == null ||
          LinuxFileIdentity.version(stagedHandle) != stagedVersion) {
        throw AtomicFileChangedException(target, cause: 'Staged file changed');
      }
      if (!parentIsCurrent()) {
        throw AtomicFileChangedException(target);
      }
      checkBeforeCommit?.call();
      final error = api.moveNoReplace(stagedHandle, targetHandle);
      if (error == LinuxAtomicFileApi.fileExistsError) {
        throw AtomicFileChangedException(target);
      }
      if (error != null) {
        throw FileSystemException(
          'Could not publish the replacement file',
          target,
          OSError('no-replace rename failed', error),
        );
      }
      published = true;
      api.flushDirectory(stagedFd, stageParent);
      api.flushDirectory(parentFd, parent);
      if (!parentIsCurrent() ||
          LinuxFileIdentity.version(recoveryHandle) != displacedVersion) {
        throw AtomicFileChangedException(
          target,
          cause: 'Original changed after publication',
        );
      }
      File(recoveryHandle).deleteSync();
      displaced = false;
    } on Object catch (error) {
      if (!published &&
          api.moveNoReplace(recoveryHandle, targetHandle) == null) {
        displaced = false;
        api.flushDirectory(parentFd, parent);
        api.flushDirectory(recoveryFd, recoveryDir.path);
        rethrow;
      }
      throw AtomicFileChangedException(
        target,
        recoveryPath: p.join(
          Link('/proc/self/fd/$recoveryFd').targetSync(),
          p.basename(target),
        ),
        cause: error,
      );
    }
  } finally {
    if (!displaced && recovery != null) {
      try {
        recovery.deleteSync();
      } on FileSystemException {
        // An empty recovery folder is safe to leave behind.
      }
    }
    for (final fd in [originalFd, recoveryFd, stagedFd, parentFd]) {
      if (fd != null) api.closeDescriptor(fd);
    }
  }
}
