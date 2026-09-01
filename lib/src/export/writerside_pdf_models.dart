import 'package:flutter/foundation.dart';

import 'markdown_pdf_models.dart';

@immutable
class WritersidePdfExportRequest {
  const WritersidePdfExportRequest({
    required this.moduleRoot,
    required this.instanceId,
    required this.destinationPath,
    required this.overwrite,
    this.projectRoot,
    this.options = const MarkdownPdfOptions(),
  });

  final String moduleRoot;
  final String? projectRoot;
  final String instanceId;
  final String destinationPath;
  final bool overwrite;
  final MarkdownPdfOptions options;
}

@immutable
class WritersidePdfExportResult {
  const WritersidePdfExportResult({
    required this.destinationPath,
    required this.pageCount,
    required this.warnings,
  });

  final String destinationPath;
  final int? pageCount;
  final List<MarkdownPdfWarning> warnings;
}

enum WritersidePdfFailureCode {
  exporterUnavailable,
  invalidRequest,
  buildFailed,
  timedOut,
  cancelled,
  invalidOutput,
  destinationExists,
  fileSystem,
}

class WritersidePdfExportException implements Exception {
  const WritersidePdfExportException(this.code, {this.detail = '', this.cause});

  final WritersidePdfFailureCode code;
  final String detail;
  final Object? cause;

  @override
  String toString() => detail.isEmpty
      ? 'Writerside PDF export failed: ${code.name}'
      : 'Writerside PDF export failed: ${code.name}: $detail';
}

class WritersidePdfCancellationToken {
  bool _cancelled = false;
  void Function()? _onCancel;

  bool get isCancelled => _cancelled;

  void cancel() {
    if (_cancelled) {
      return;
    }
    _cancelled = true;
    _onCancel?.call();
  }

  void throwIfCancelled() {
    if (_cancelled) {
      throw const WritersidePdfExportException(
        WritersidePdfFailureCode.cancelled,
      );
    }
  }

  void attach(void Function() onCancel) {
    _onCancel = onCancel;
    if (_cancelled) {
      onCancel();
    }
  }

  void detach() {
    _onCancel = null;
  }
}
