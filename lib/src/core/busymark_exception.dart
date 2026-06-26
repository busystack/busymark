class BusyMarkException implements Exception {
  const BusyMarkException(this.code, {this.args = const {}});

  final String code;
  final Map<String, Object?> args;

  @override
  String toString() => 'BusyMarkException($code)';
}
