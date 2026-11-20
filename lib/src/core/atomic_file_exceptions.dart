class AtomicFileAlreadyExistsException implements Exception {
  const AtomicFileAlreadyExistsException(this.path);

  final String path;

  @override
  String toString() => 'A filesystem entity already exists at "$path".';
}

class AtomicFileChangedException implements Exception {
  const AtomicFileChangedException(this.path, {this.recoveryPath, this.cause});

  final String path;
  final String? recoveryPath;
  final Object? cause;

  @override
  String toString() {
    final recovery = recoveryPath == null
        ? ''
        : ' The displaced version was preserved at "$recoveryPath".';
    final detail = cause == null ? '' : ' Validation failed: $cause.';
    return 'The file at "$path" changed during publication.$recovery$detail';
  }
}
