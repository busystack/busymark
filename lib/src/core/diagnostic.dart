import 'source_span.dart';

enum DiagnosticSeverity { error, warning, info, hint }

extension DiagnosticSeverityX on DiagnosticSeverity {
  String get label => name;

  int get rank {
    return switch (this) {
      DiagnosticSeverity.error => 4,
      DiagnosticSeverity.warning => 3,
      DiagnosticSeverity.info => 2,
      DiagnosticSeverity.hint => 1,
    };
  }
}

class Diagnostic {
  const Diagnostic({
    required this.code,
    required this.severity,
    required this.filePath,
    this.args = const {},
    this.sourceSpan,
    this.relatedSpans = const [],
  });

  final String code;
  final DiagnosticSeverity severity;
  final String filePath;
  final Map<String, Object?> args;
  final SourceSpan? sourceSpan;
  final List<SourceSpan> relatedSpans;

  int? get line => sourceSpan?.startLine;
  int? get column => sourceSpan?.startColumn;

  Map<String, Object?> toJson() => {
    'code': code,
    'severity': severity.label,
    'file': filePath,
    if (args.isNotEmpty) 'args': args,
    'line': line,
    'column': column,
  };
}

List<Diagnostic> sortDiagnostics(Iterable<Diagnostic> diagnostics) {
  return diagnostics.toList()..sort((a, b) {
    final severity = b.severity.rank.compareTo(a.severity.rank);
    if (severity != 0) {
      return severity;
    }
    final file = a.filePath.compareTo(b.filePath);
    if (file != 0) {
      return file;
    }
    return (a.sourceSpan?.startOffset ?? 0).compareTo(
      b.sourceSpan?.startOffset ?? 0,
    );
  });
}
