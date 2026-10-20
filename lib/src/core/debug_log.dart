import 'dart:io';

import 'package:path/path.dart' as p;

bool debugBusyMarkLogging = const bool.fromEnvironment(
  'BUSYMARK_DEBUG_LOGGING',
);

void busyMarkDebugLogLines(Iterable<String> lines) {
  if (!debugBusyMarkLogging) {
    return;
  }
  for (final line in lines) {
    stderr.writeln(line);
  }
}

void busyMarkDebugLogError(
  String title,
  Object error,
  StackTrace stackTrace, {
  Map<String, String> context = const {},
}) {
  if (!debugBusyMarkLogging) {
    return;
  }
  stderr.writeln(title);
  for (final entry in context.entries) {
    stderr.writeln('[BusyMark]   ${entry.key}: ${entry.value}');
  }
  stderr.writeln('[BusyMark]   error type: ${error.runtimeType}');
  stderr.writeln('[BusyMark]   stack trace:\n$stackTrace');
}

String busyMarkLogPath(String path) {
  final trimmed = path.trim();
  if (trimmed.isEmpty) {
    return '<empty>';
  }
  final uri = Uri.tryParse(trimmed);
  if (uri != null && uri.hasScheme) {
    final name = p.basename(uri.path);
    return name.isEmpty
        ? '${uri.scheme}:<redacted>'
        : '${uri.scheme}:.../$name';
  }
  final name = p.basename(trimmed);
  return name.isEmpty ? '<redacted>' : '.../$name';
}
